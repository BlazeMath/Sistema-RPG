"""Conferir o escopo e a composição das três alterações aprovadas pelo autor."""
import hashlib,json
from pathlib import Path
from pypdf import PdfReader

ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'dados'
old=json.loads((D/'catalogo_cartas_antes_ajuste_area_v05.json').read_text(encoding='utf-8'))['cartas']
new=json.loads((D/'catalogo_cartas.json').read_text(encoding='utf-8'))['cartas']
allowed={'EQ-042':{'campos','habilidade','diagramacao','revisao','fonte'},
         'EQ-043':{'habilidade','revisao','fonte'},'EQ-044':{'habilidade','revisao','fonte'}}
assert len(old)==len(new)==156
for a,b in zip(old,new):
    assert a['id']==b['id']
    changed={k for k in a.keys()|b.keys() if a.get(k)!=b.get(k)}
    assert changed<=allowed.get(a['id'],set()),(a['id'],changed)
    assert a['imagem']==b['imagem']
byid={c['id']:c for c in new}
assert byid['EQ-042']['campos']['Alcance']=='Longo'
assert 'incluindo aliados' in byid['EQ-042']['habilidade']
assert 'depois de resolver esta habilidade, você sofre 3 de dano de Raio' in byid['EQ-042']['habilidade']
assert byid['EQ-042']['diagramacao']=='frente_verso'
assert 'Oculto no início do ataque' in byid['EQ-043']['habilidade']
assert 'inimigos adjacentes' not in byid['EQ-043']['habilidade']
assert '3 × 3 quadrados' in byid['EQ-044']['habilidade']

text_changes={}
for kind,count,expected in [('Cartas',312,{83,84,86,88}),('A4',36,{9,10})]:
    a=PdfReader(ROOT/f'pdf/Sistema21_Equipamentos_156_{kind}_v04.pdf')
    b=PdfReader(ROOT/f'pdf/Sistema21_Equipamentos_156_{kind}_v05.pdf')
    assert len(a.pages)==len(b.pages)==count
    changes={i for i,(x,y) in enumerate(zip(a.pages,b.pages),1) if x.extract_text()!=y.extract_text()}
    assert changes==expected,(kind,changes)
    text_changes[kind]=sorted(changes)

digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
image_changes={}
for folder,prefix,count,expected in [('individuais','carta-',312,{83,84,86,88}),('colecao','a4-',36,{9,10})]:
    a=ROOT/'previews'/f'{folder}_v04'
    b=ROOT/'previews'/f'{folder}_v05'
    files=sorted(a.glob(prefix+'*.png'))
    assert len(files)==len(list(b.glob(prefix+'*.png')))==count
    changes={int(x.stem.split('-')[-1]) for x in files if digest(x)!=digest(b/x.name)}
    assert changes==expected,(folder,changes)
    image_changes[folder]=sorted(changes)

qa={'versao':'v05','base':'v04','itens_alterados':sorted(allowed),
    'artes_preservadas':156,'total_paginas_renderizadas':348,
    'alteracoes_textuais':text_changes,'alteracoes_visuais':image_changes,
    'demais_paginas_identicas':True,'regras_aprovadas_conferidas':True}
(D/'qa_regras_raras_v05.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(qa,ensure_ascii=False))
