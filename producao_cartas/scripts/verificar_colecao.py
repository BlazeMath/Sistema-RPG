import json,re,sys
from pathlib import Path
from pypdf import PdfReader
import pdfplumber
from reportlab.lib.units import mm
from montar_piloto import COST_RE
from montar_colecao import VERSION,TOTAL,PAGES_A4

ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'dados/catalogo_cartas.json').read_text(encoding='utf-8'));cards=data['cartas']
normal=lambda s:''.join(c.lower() for c in str(s) if c.isalnum())
def no_cost(text):return COST_RE.sub('',text)
def expected_drops(card,front):
    text=card['habilidade'] if not front or card['diagramacao']!='frente_verso' else ''
    costs=sum(int(n) for n in COST_RE.findall(text) if 1<=int(n)<=12)
    return costs+int('Limite de Fadiga' in card['campos'])+int('GRIMÓRIO' in card['categoria'] or card['categoria']=='TEXTO SAGRADO')

card_file=ROOT/f'pdf/Sistema21_Equipamentos_{TOTAL}_Cartas_{VERSION}.pdf'
a4_file=ROOT/f'pdf/Sistema21_Equipamentos_{TOTAL}_A4_{VERSION}.pdf'
r=PdfReader(card_file);assert len(r.pages)==2*TOTAL
ra=PdfReader(a4_file);assert len(ra.pages)==PAGES_A4
textchecks=[]
for i,card in enumerate(cards):
    front,back=r.pages[2*i:2*i+2]
    ft,bt=front.extract_text(),back.extract_text()
    for page,text in [(front,ft),(back,bt)]:
        assert abs(float(page.mediabox.width)/mm-63)<.01 and abs(float(page.mediabox.height)/mm-88)<.01
        assert card['id'] in text and card['nome'] in text
        assert all(normal(part) in normal(text) for part in card['categoria'].split('·'))
        for tag in card['tags']:assert normal(tag) in normal(text),(card['id'],tag)
        for key in ['Dano','Vida','Resistência','Requisito','Magias']:
            if key in card['campos']:assert normal(card['campos'][key]) in normal(text),(card['id'],key)
        if card['campos'].get('Alcance'):
            value=card['campos']['Alcance']
            melee=re.fullmatch(r'Corpo a corpo \((\d+)\)',value)
            expected=melee.group(1)+' quadrado'+('s' if melee.group(1)!='1' else '') if melee else value
            assert normal(expected) in normal(text),(card['id'],'Alcance')
    assert normal(no_cost(card['habilidade'])) in normal(bt),(card['id'],'habilidade incompleta')
    for page,is_front in [(front,True),(back,False)]:
        images=[v for v in page['/Resources'].get('/XObject',{}).values() if v.get_object().get('/Subtype')=='/Image']
        assert len(images)==int(is_front),(card['id'],'imagem na face errada')
    textchecks.append(card['id'])

# Os custos são ícones vetoriais: conferir a quantidade de gotas além do texto extraído.
orange=(1.0,103/255,31/255)
def orange_drops(page):
    return sum(1 for c in page.curves if c.get('fill') and isinstance(c.get('non_stroking_color'),(tuple,list)) and len(c['non_stroking_color'])==3 and all(abs(a-b)<.002 for a,b in zip(c['non_stroking_color'],orange)))
with pdfplumber.open(card_file) as doc:
    for i,card in enumerate(cards):
        for j in [0,1]:
            p=doc.pages[2*i+j];assert orange_drops(p)==expected_drops(card,j==0),(card['id'],j,orange_drops(p),expected_drops(card,j==0));p.close()
mapping=json.loads((ROOT/f'dados/imposicao_colecao_{VERSION}.json').read_text(encoding='utf-8'))
assert len(mapping)==TOTAL and {x['id'] for x in mapping}=={x['id'] for x in cards}
for m in mapping:
    assert m['coluna_frente']+m['coluna_verso']==4
    assert abs(m['verso_x']-(float(ra.pages[0].mediabox.width)-m['frente_x']-63*mm))<.001
    for key in ['pagina_frente','pagina_verso']:assert m['id'] in ra.pages[m[key]-1].extract_text()
measure=json.loads((ROOT/f'dados/medidas_colecao_{VERSION}.json').read_text(encoding='utf-8'))
assert len(measure)==TOTAL and all(x['corpo_pt']>=8 and x['texto_altura_mm']<=x['espaco_mm']+.02 for x in measure)
result={'itens':TOTAL,'frentes':TOTAL,'versos':TOTAL,'paginas_cartas':2*TOTAL,'paginas_A4':PAGES_A4,'texto_integral_validado':len(textchecks),'dados_repetidos':True,'custos_e_limites_conferidos_por_gotas_vetoriais':True,'menor_fonte_corpo_pt':8,'versos_compactos':[x['id'] for x in measure if x['verso_compacto']],'imposicao_duplex':'validada para virar pela borda longa','arquivos':[{'arquivo':str(p),'bytes':p.stat().st_size} for p in [card_file,a4_file]]}
(ROOT/f'dados/qa_colecao_{VERSION}.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
