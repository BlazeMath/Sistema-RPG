"""Coleção completa: dados repetidos e habilidades integrais nos versos."""
import json,re,sys,hashlib,io
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from pypdf import PdfReader,PdfWriter,PageObject,Transformation
import montar_piloto as m

ROOT=m.ROOT
VERSION=sys.argv[sys.argv.index('--version')+1] if '--version' in sys.argv else 'v01'
assert re.fullmatch(r'v\d{2}',VERSION),VERSION
CARDS=m.DATA['cartas']
TOTAL=len(CARDS)
PAGES_A4=2*((TOTAL+8)//9)
m.SYMBOL_RULES['conjuracao']=[c['id'] for c in CARDS if 'GRIMÓRIO' in c['categoria'] or c['categoria']=='TEXTO SAGRADO']
report=[]

def back_profile(card):
    face=dict(card);face['diagramacao']='frente_verso'
    p,h,size=m.back_paragraph(face)
    top=m.back_text_top(face)
    if h<=top-m.BACK_BOTTOM:return {'compacto':False,'p':p,'h':h,'size':size,'top':top,'bottom':m.BACK_BOTTOM}
    # Quatro livros longos: requisitos e tags mais próximos e margens de 2 mm.
    top=m.H-14*mm
    _,th=m.tag_positions(m.display_tags(card),m.W-4*mm)
    top-=th+1.4*mm
    bottom=6.5*mm
    for size in [9,8.5,8]:
        p,h=m.para(card['habilidade'],m.W-4*mm,size,size*1.2 if size>8 else 8.8)
        if h<=top-bottom:return {'compacto':True,'p':p,'h':h,'size':size,'top':top,'bottom':bottom}
    raise ValueError(f"Texto não cabe sem reduzir abaixo de 8 pt: {card['id']}: {h} > {top-bottom}")

def compact_back(c,card,x,y,profile):
    c.saveState();c.translate(x,y)
    rarity=card['categoria'].rsplit('·',1)[-1].strip();edge=HexColor(m.RARITY.get(rarity,m.RARITY['COMUM']))
    c.setFillColor(m.BG);c.setStrokeColor(edge);c.setLineWidth(.8);c.roundRect(.5,.5,m.W-1,m.H-1,5,fill=1,stroke=1)
    c.setFillColor(m.PANEL);c.roundRect(1.5,m.H-13*mm,m.W-3,12.5*mm,4,fill=1,stroke=0)
    c.setFillColor(m.MUTED);c.setFont('Body',5.2);c.drawString(3*mm,m.H-3.2*mm,card['id']+' / MMR / VERSO'+(' / '+rarity if rarity in m.RARITY else ''))
    c.setFillColor(m.INK);c.setFont('Title',m.title_size(card['nome']));c.drawString(3*mm,m.H-7.8*mm,card['nome'])
    c.setFillColor(edge);c.setFont('Body',5.7)
    c.drawString(3*mm,m.H-11.1*mm,'Requer '+m.plain(card['campos']['Requisito']) if card['campos'].get('Requisito') else m.plain(card['categoria']))
    if card['campos'].get('Magias'):c.drawRightString(m.W-3*mm,m.H-11.1*mm,card['campos']['Magias']+' MAGIAS')
    top=m.H-14*mm;f=card['campos']
    assert 'Dano' not in f and 'Vida' not in f,card['id']
    tags,th=m.tag_positions(m.display_tags(card),m.W-4*mm)
    for tag,tx,ty,tw,hh in tags:
        c.setStrokeColor(edge);c.setLineWidth(.45);c.roundRect(2*mm+tx,top-ty-hh,tw,hh,hh/2,fill=0,stroke=1)
        if tag=='@conjuracao':m.draw_conjuration(c,2*mm+tx+5,top-ty-hh+1.5)
        else:c.setFillColor(m.MUTED);c.setFont('Body',6.1);c.drawString(2*mm+tx+5,top-ty-hh+3,tag)
    profile['p'].drawOn(c,2*mm,profile['top']-profile['h'])
    c.setStrokeColor(HexColor('#625D50'));c.line(3*mm,5.6*mm,m.W-3*mm,5.6*mm)
    c.setFillColor(m.MUTED);c.setFont('Body',5);c.drawString(3*mm,2.9*mm,'MESMO ITEM / '+card['id']);m.draw_limit(c,card)
    c.restoreState()

def back(c,card,x,y):
    profile=back_profile(card)
    if profile['compacto']:compact_back(c,card,x,y,profile)
    else:
        face=dict(card);face['diagramacao']='frente_verso';m.draw_back(c,face,x,y)
        if not card['habilidade']:
            c.saveState();c.setFillColor(m.MUTED);c.setFont('Title',28);c.drawCentredString(x+m.W/2,y+18*mm,'21');c.restoreState()
    return profile

def load_assets(require_all=True):
    for card in CARDS:
        if card.get('imagem') and (ROOT/card['imagem']).is_file():continue
        meta=ROOT/'dados'/f"{card['id']}_arte_v01.json"
        if meta.exists():card['imagem']=json.loads(meta.read_text(encoding='utf-8'))['arquivo']
        if require_all:assert card.get('imagem') and (ROOT/card['imagem']).is_file(),card['id']

def measure():
    result=[]
    for card in CARDS:
        p=back_profile(card)
        title_width=m.pdfmetrics.stringWidth(card['nome'],'Title',m.title_size(card['nome']))
        assert title_width<=m.W-6*mm+.01,card['id']
        face=m.front_of(card);metric=m.layout(face)[-1];assert metric['fit'],card['id']
        result.append({'id':card['id'],'verso_compacto':p['compacto'],'corpo_pt':p['size'],'texto_altura_mm':round(p['h']/mm,2),'espaco_mm':round((p['top']-p['bottom'])/mm,2),'arte_frente_mm':metric['arte_mm']})
    (ROOT/f'dados/medidas_colecao_{VERSION}.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    return result

def create_canvas(path,page_size,title):
    c=canvas.Canvas(str(path) if isinstance(path,(str,Path)) else path,pagesize=page_size,pageCompression=1)
    c.setTitle(title);c.setAuthor('Sistema 21 / Masmorras');c.setNamedCB('fatigue_symbols',m.fatigue_callback)
    return c

def card_pdf():
    path=ROOT/f'pdf/Sistema21_Equipamentos_{TOTAL}_Cartas_{VERSION}.pdf'
    c=create_canvas(path,(m.W,m.H),f'Sistema 21 - {TOTAL} equipamentos, frente e verso')
    for card in CARDS:
        m.draw_card(c,m.front_of(card),0,0);c.showPage()
        back(c,card,0,0);c.showPage()
    c.save();return path

def print_pdf(card_file):
    # Montar A4 a partir das próprias faces prontas evita recodificar as artes
    # e garante que o conteúdo nas duas versões seja idêntico.
    path=ROOT/f'pdf/Sistema21_Equipamentos_{TOTAL}_A4_{VERSION}.pdf'
    source=PdfReader(card_file);writer=PdfWriter();overlay=io.BytesIO()
    c=create_canvas(overlay,A4,'Sistema 21 - impressão A4 duplex')
    pw,ph=A4;gap=3*mm;sx=(pw-3*m.W-2*gap)/2;sy=(ph-3*m.H-2*gap)/2
    mapping=[];placements=[]
    for offset in range(0,len(CARDS),9):
        group=CARDS[offset:offset+9]
        for face in ['FRENTE','VERSO']:
            page_placements=[]
            c.setFillColor(HexColor('#454545'));c.setFont('Body',7)
            c.drawString(sx,ph-6*mm,f'SISTEMA 21 / EQUIPAMENTOS / FOLHA {offset//9+1:02d} / {face}')
            for i,card in enumerate(group):
                col=i%3;row=i//3;drawcol=col if face=='FRENTE' else 2-col
                x=sx+drawcol*(m.W+gap);y=sy+(2-row)*(m.H+gap)
                source_page=2*(offset+i)+(0 if face=='FRENTE' else 1)
                page_placements.append((source_page,x,y))
                m.crop_marks(c,x,y)
                if face=='VERSO':mapping.append({'id':card['id'],'pagina_frente':offset//9*2+1,'pagina_verso':offset//9*2+2,'linha':row+1,'coluna_frente':col+1,'coluna_verso':drawcol+1,'frente_x':sx+col*(m.W+gap),'verso_x':x,'y':y})
            c.setFillColor(HexColor('#454545'));c.setFont('Body',6)
            c.drawString(sx,5.5*mm,'63 × 88 mm / escala 100% / frente e verso pela borda longa / fazer uma folha de teste')
            c.showPage();placements.append(page_placements)
    c.save();overlay.seek(0);overlays=PdfReader(overlay)
    for index,items in enumerate(placements):
        page=PageObject.create_blank_page(width=pw,height=ph)
        for source_page,x,y in items:page.merge_transformed_page(source.pages[source_page],Transformation().translate(tx=x,ty=y))
        page.merge_page(overlays.pages[index]);writer.add_page(page)
    writer.add_metadata({'/Title':f'Sistema 21 - {TOTAL} equipamentos - impressão A4 duplex','/Author':'Sistema 21 / Masmorras'})
    with path.open('wb') as output:writer.write(output)
    (ROOT/f'dados/imposicao_colecao_{VERSION}.json').write_text(json.dumps(mapping,ensure_ascii=False,indent=2),encoding='utf-8')
    return path

if __name__=='__main__':
    load_assets('--measure' not in sys.argv)
    result=measure()
    if '--measure' in sys.argv:
        print(json.dumps({'itens':len(result),'compactos':[x['id'] for x in result if x['verso_compacto']],'menor_corpo':min(x['corpo_pt'] for x in result)},ensure_ascii=False));sys.exit(0)
    individual=card_pdf();files=[individual,print_pdf(individual)]
    (ROOT/f'dados/verificacao_colecao_{VERSION}.json').write_text(json.dumps({'arquivos':[str(f) for f in files],'medidas':result,'simbolos':m.symbol_usage},ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'pdfs':[str(f) for f in files],'itens':len(CARDS),'paginas_individuais':len(CARDS)*2,'paginas_A4':PAGES_A4},ensure_ascii=False))
