import sys,json,html,re,math
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor,Color
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph
from reportlab.lib.utils import ImageReader
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]/'producao_cartas'
DATA=json.loads((ROOT/'dados/catalogo_cartas.json').read_text(encoding='utf-8'))
BYID={c['id']:c for c in DATA['cartas']}
for name,file in [('Body','arial.ttf'),('BodyBold','arialbd.ttf'),('Title','georgiab.ttf')]:
    pdfmetrics.registerFont(TTFont(name,str(Path(r'C:\Windows\Fonts')/file)))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='BodyBold',italic='Body',boldItalic='BodyBold')
W,H=63*mm,88*mm
INK=HexColor('#EDE3CE');MUTED=HexColor('#C5BCA9');BG=HexColor('#171612');PANEL=HexColor('#292923')
RARITY={'COMUM':'#A9AAA2','INCOMUM':'#87A38C','RARA':'#D0AA65'}
metrics=[]
duplex_map=[]
MIN_ART=28*mm
BACK_TOP=H-17*mm
BACK_BOTTOM=7*mm
BACK_AVAILABLE=BACK_TOP-BACK_BOTTOM
FATIGUE=HexColor('#FF671F')
SYMBOL_RULES=json.loads((ROOT/'dados/simbolos_piloto.json').read_text(encoding='utf-8'))
symbol_usage=[]
_revision_registry=ROOT/'dados/artes_revisadas.json'
IMAGE_ROTATIONS={r['id']:r.get('rotacao_diagramacao_graus',0) for r in json.loads(_revision_registry.read_text(encoding='utf-8'))} if _revision_registry.exists() else {}
COST_RE=re.compile(r'\b(\d+) de fadiga(?=\s*(?:e\s*\d+\s+de\s+vida\s*)?(?:,\s*[^:.\n<>]{1,40})?\s*:)',re.IGNORECASE)

def draw_drop(c,x,y,width=4,height=7):
    c.saveState();c.translate(x,y);c.scale(width,height)
    p=c.beginPath();p.moveTo(.5,1)
    p.curveTo(.43,.78,.03,.42,.03,.25)
    p.curveTo(.03,-.08,.97,-.08,.97,.25)
    p.curveTo(.97,.42,.57,.78,.5,1);p.close()
    c.setFillColor(FATIGUE);c.drawPath(p,fill=1,stroke=0);c.restoreState()

def fatigue_callback(c,kind,label):
    count,size=label.split('|');count=int(count);size=float(size)
    tx=c._curr_tx_info
    for i in range(count):draw_drop(c,tx['cur_x']-count*size*.6+i*size*.6,tx['cur_y']-.05*size,size*.49,size*.84)
    symbol_usage.append({'tipo':'custo_fadiga','valor':count,'pagina':c.getPageNumber()})

def fatigue_markup(match,size):
    count=int(match.group(1))
    if count<1 or count>12:return match.group(0)
    return f'<nobr><font name="Courier" size="{size}">'+'&#160;'*count+f'</font><onDraw name="fatigue_symbols" label="{count}|{size}"/></nobr>'

def draw_conjuration(c,x,y,width=10,height=8):
    c.saveState();c.setFillColor(HexColor('#D9DDE5'));c.setStrokeColor(HexColor('#7E8797'));c.setLineWidth(.35)
    c.roundRect(x,y,width*.7,height*.72,.6,fill=1,stroke=1)
    c.roundRect(x+width*.27,y+height*.03,width*.7,height*.72,.6,fill=1,stroke=1)
    draw_drop(c,x+width*.33,y+height*.18,width*.39,height*.84)
    c.restoreState();symbol_usage.append({'tipo':'conjuracao','pagina':c.getPageNumber()})

def display_tags(card):
    return (['@conjuracao'] if card['id'] in SYMBOL_RULES['conjuracao'] else [])+card['tags']

def draw_limit(c,card):
    value=card['campos'].get('Limite de Fadiga')
    if value is None:return
    right=W-3*mm;baseline=2.9*mm
    number_width=pdfmetrics.stringWidth(value,'BodyBold',7)
    c.setFillColor(INK);c.setFont('BodyBold',7);c.drawRightString(right,baseline,value)
    drop_x=right-number_width-5.7
    draw_drop(c,drop_x,baseline-.2,3.5,5.8)
    c.setFillColor(MUTED);c.setFont('Body',5.2);c.drawRightString(drop_x-3,baseline,'LIMITE DE FADIGA')
    symbol_usage.append({'tipo':'limite_fadiga','id':card['id'],'valor':int(value),'pagina':c.getPageNumber()})

def front_of(card):
    if not needs_back(card):return card
    card=dict(card)
    card['habilidade']=''
    card['_has_back']=True
    return card

def plain(t):return str(t).replace('—','-').replace('–','-').replace('\u2011','-')
def rich(t,size=8):
    out=[]
    for line in t.splitlines():
        line=html.escape(plain(line))
        if ':' in line:
            before,after=line.split(':',1)
            if len(before)<85:line='<b>'+before+':</b>'+after
        line=COST_RE.sub(lambda m:fatigue_markup(m,size),line)
        out.append(line)
    return '<br/>'.join(out)

def para(t,width,size=8,leading=9.35,color=INK):
    p=Paragraph(rich(t,size),ParagraphStyle('body',fontName='Body',fontSize=size,leading=leading,textColor=color,spaceAfter=0,spaceBefore=0))
    pw,ph=p.wrap(width,1000)
    return p,ph

def tag_positions(tags,width):
    x=0;y=0;result=[];font=6.1;height=10.5
    for tag in tags:
        tw=20 if tag=='@conjuracao' else pdfmetrics.stringWidth(tag,'Body',font)+10
        if x+tw>width and x>0:x=0;y+=height+3
        result.append((tag,x,y,tw,height));x+=tw+4
    return result,y+height if result else 0

def layout(card):
    f=card['campos']; top=H-15*mm
    stats=('Dano' in f or 'Vida' in f)
    if stats:top-=10*mm
    if 'Requisito' in f:top-=4.8*mm
    _,th=tag_positions(display_tags(card),W-6*mm)
    top-=th+4
    bottom=6.8*mm
    p,ph=para(card['habilidade'],W-6.4*mm) if card['habilidade'] else (None,0)
    available=top-bottom
    art_h=available-ph-(4*mm if ph else 0)
    metric={'id':card['id'],'texto_pt':round(ph,1),'arte_mm':round(art_h/mm,1),'font_pt':8,'fit':art_h>=9*mm}
    return top,bottom,p,ph,art_h,metric

def needs_back(card):
    if card.get('diagramacao') in ['frente_verso','frente_unica']:
        return card['diagramacao']=='frente_verso'
    return bool(card['habilidade']) and layout(card)[4]<MIN_ART

def back_paragraph(card):
    available=back_text_top(card)-BACK_BOTTOM
    for size in [9,8.5,8]:
        p,h=para(card['habilidade'],W-6.4*mm,size,size*1.2 if size>8 else 9)
        if h<=available:return p,h,size
    return p,h,size

def back_text_top(card):
    face=dict(card);face['habilidade']=''
    return layout(face)[0]-3*mm

def draw_item_data(c,card,edge):
    """Dados idênticos nas duas faces, a partir do mesmo registro."""
    f=card['campos'];top=H-15*mm
    if 'Dano' in f or 'Vida' in f:
        keys=['Dano','Alcance'] if 'Dano' in f else ['Vida','Resistência']
        c.setFillColor(PANEL);c.rect(2*mm,top-9*mm,W-4*mm,9*mm,fill=1,stroke=0)
        for i,key in enumerate(keys):
            cx=W/4 if i==0 else W*3/4
            c.setFont('Body',5.2);c.setFillColor(MUTED);c.drawCentredString(cx,top-2.6*mm,key.upper())
            val=plain(f.get(key,'-'))
            if key=='Alcance':
                melee=re.fullmatch(r'Corpo a corpo \((\d+)\)',val)
                if melee:val=melee.group(1)+' quadrado'+('s' if melee.group(1)!='1' else '')
            c.setFont('BodyBold',8);c.setFillColor(INK);c.drawCentredString(cx,top-6.6*mm,val)
        top-=10*mm
    if 'Requisito' in f:
        c.setFont('Body',6.5);c.setFillColor(INK);c.drawString(3*mm,top-2.7*mm,'Requer '+plain(f['Requisito']))
        if 'Magias' in f:
            c.setFont('BodyBold',6);c.drawRightString(W-3*mm,top-2.7*mm,f['Magias']+' MAGIAS')
        top-=4.8*mm
    tags,th=tag_positions(display_tags(card),W-6*mm)
    for tag,tx,ty,tw,hh in tags:
        c.setStrokeColor(edge);c.setLineWidth(.45)
        c.roundRect(3*mm+tx,top-ty-hh,tw,hh,hh/2,fill=0,stroke=1)
        if tag=='@conjuracao':draw_conjuration(c,3*mm+tx+5,top-ty-hh+1.5)
        else:
            c.setFillColor(MUTED);c.setFont('Body',6.1);c.drawString(3*mm+tx+5,top-ty-hh+3,tag)
    return top-th-4

def image_fit(c,file,x,y,width,height,rotation=0):
    reader=ImageReader(str(file));iw,ih=reader.getSize();scale=min(width/iw,height/ih)
    if rotation:
        # Apenas composição no PDF: ler o limite alfa, sem alterar o PNG.
        with Image.open(file) as asset:
            # Ignorar somente a névoa quase transparente ao medir a composição.
            # O desenho completo continua sendo incorporado, com o alfa original.
            bounds=asset.getchannel('A').point([0]*64+[255]*192).getbbox()
        left,top,right,bottom=bounds
        bw,bh=right-left,bottom-top;a=math.radians(rotation)
        rw=abs(bw*math.cos(a))+abs(bh*math.sin(a));rh=abs(bw*math.sin(a))+abs(bh*math.cos(a))
        scale=.96*min(width/rw,height/rh)
        c.saveState();clip=c.beginPath();clip.rect(x,y,width,height);c.clipPath(clip,stroke=0,fill=0)
        c.translate(x+width/2,y+height/2);c.rotate(rotation);c.scale(scale,scale)
        c.drawImage(reader,-(left+right)/2,-(ih-(top+bottom)/2),width=iw,height=ih,mask='auto')
        c.restoreState();return
    dw,dh=iw*scale,ih*scale
    c.drawImage(reader,x+(width-dw)/2,y+(height-dh)/2,width=dw,height=dh,mask='auto')

def title_size(text,width=W-6*mm):
    return max(8,min(10.2,10.2*width/max(1,pdfmetrics.stringWidth(text,'Title',10.2))))

def draw_card(c,card,x,y):
    c.saveState();c.translate(x,y)
    rarity=card['categoria'].rsplit('·',1)[-1].strip()
    if rarity not in RARITY:rarity='COMUM'
    edge=HexColor(RARITY[rarity])
    c.setFillColor(BG);c.setStrokeColor(edge);c.setLineWidth(.8)
    c.roundRect(.5,.5,W-1,H-1,5,fill=1,stroke=1)
    c.setFillColor(PANEL);c.roundRect(1.5,H-13*mm,W-3,12.5*mm,4,fill=1,stroke=0)
    c.setFillColor(MUTED);c.setFont('Body',5.2);c.drawString(3*mm,H-3.2*mm,card['id']+'  /  MMR')
    c.setFont('Title',title_size(card['nome']));c.setFillColor(INK)
    c.drawString(3*mm,H-7.8*mm,card['nome'])
    c.setFont('Body',5.7);c.setFillColor(edge)
    c.drawString(3*mm,H-11.1*mm,plain(card['categoria']))
    top=draw_item_data(c,card,edge)
    _,bottom,p,ph,art_h,m=layout(card)
    assert art_h>=9*mm,(card['id'],m)
    image_fit(c,ROOT/card['imagem'],3.2*mm,top-art_h,W-6.4*mm,art_h,IMAGE_ROTATIONS.get(card['id'],0))
    if p:
        text_y=bottom
        c.setStrokeColor(HexColor('#625D50'));c.setLineWidth(.4)
        c.line(3*mm,text_y+ph+2.5*mm,W-3*mm,text_y+ph+2.5*mm)
        p.drawOn(c,3.2*mm,text_y)
    c.setStrokeColor(HexColor('#625D50'));c.line(3*mm,5.6*mm,W-3*mm,5.6*mm)
    c.setFont('Body',5);c.setFillColor(MUTED);c.drawString(3*mm,2.9*mm,'HABILIDADES NO VERSO' if card.get('_has_back') else 'MASMORRAS')
    draw_limit(c,card)
    m['modo']='frente_verso' if card.get('_has_back') else 'texto_na_frente'
    c.restoreState();metrics.append(m)

def draw_back(c,card,x,y):
    c.saveState();c.translate(x,y)
    rarity=card['categoria'].rsplit('·',1)[-1].strip()
    if rarity not in RARITY:rarity='COMUM'
    edge=HexColor(RARITY[rarity])
    c.setFillColor(BG);c.setStrokeColor(edge);c.setLineWidth(.8)
    c.roundRect(.5,.5,W-1,H-1,5,fill=1,stroke=1)
    c.setFillColor(PANEL);c.roundRect(1.5,H-13*mm,W-3,12.5*mm,4,fill=1,stroke=0)
    c.setFillColor(MUTED);c.setFont('Body',5.2);c.drawString(3*mm,H-3.2*mm,card['id']+' / MMR / VERSO')
    c.setFillColor(INK);c.setFont('Title',title_size(card['nome']));c.drawString(3*mm,H-7.8*mm,card['nome'])
    c.setFillColor(edge);c.setFont('Body',5.7)
    c.drawString(3*mm,H-11.1*mm,plain(card['categoria']) if needs_back(card) else 'SISTEMA 21 / MASMORRAS')
    if needs_back(card):
        draw_item_data(c,card,edge)
        text_top=back_text_top(card)
        p,h,size=back_paragraph(card)
        assert h<=text_top-BACK_BOTTOM,(card['id'],h)
        p.drawOn(c,3.2*mm,text_top-h)
        metrics.append({'id':card['id'],'face':'verso','font_pt':size,'texto_pt':round(h,1),'texto_top_mm':round(text_top/mm,2),'texto_base_mm':round((text_top-h)/mm,2),'dados_repetidos':True,'fit':True})
    else:
        cy=H*.48
        c.setStrokeColor(HexColor('#666052'));c.setLineWidth(.8)
        c.circle(W/2,cy,19*mm,fill=0,stroke=1)
        c.circle(W/2,cy,17*mm,fill=0,stroke=1)
        c.setFillColor(MUTED);c.setFont('Title',38);c.drawCentredString(W/2,cy-5*mm,'21')
        c.setFont('Body',6.5);c.drawCentredString(W/2,cy-26*mm,'COLEÇÃO MASMORRAS')
    c.setStrokeColor(HexColor('#625D50'));c.line(3*mm,5.6*mm,W-3*mm,5.6*mm)
    c.setFont('Body',5);c.setFillColor(MUTED);c.drawString(3*mm,2.9*mm,'MESMO ITEM / '+card['id'])
    draw_limit(c,card)
    c.restoreState()

def crop_marks(c,x,y):
    c.setStrokeColor(HexColor('#727272'));c.setLineWidth(.25);l=1.3*mm;gap=.6*mm
    for px in [x,x+W]:
        for py in [y,y+H]:
            dx=-1 if px==x else 1;dy=-1 if py==y else 1
            c.line(px+dx*gap,py,px+dx*(gap+l),py)
            c.line(px,py+dy*gap,px,py+dy*(gap+l))

def pilot_pdf():
    out=ROOT/'pdf/Cartas_Equipamentos_Piloto_v03_Simbolos.pdf'
    c=canvas.Canvas(str(out),pagesize=A4);c.setTitle('Sistema 21 - nove cartas-piloto')
    c.setNamedCB('fatigue_symbols',fatigue_callback)
    c.setAuthor('Sistema 21');pw,ph=A4
    gx=gy=3*mm;startx=(pw-(3*W+2*gx))/2;starty=(ph-(3*H+2*gy))/2
    c.setFont('Body',7);c.setFillColor(HexColor('#454545'))
    c.drawString(startx,ph-6*mm,'SISTEMA 21 / MASMORRAS / PILOTO 03 / FRENTES')
    for i,ident in enumerate(DATA['piloto']):
        x=startx+(i%3)*(W+gx);y=starty+(2-i//3)*(H+gy)
        draw_card(c,front_of(BYID[ident]),x,y);crop_marks(c,x,y)
    c.setFont('Body',6);c.drawString(startx,5.5*mm,'63 × 88 mm / Escala 100% / Frente e verso: virar pela borda longa / Fazer uma folha de teste.')
    c.showPage()
    c.setFont('Body',7);c.setFillColor(HexColor('#454545'))
    c.drawString(startx,ph-6*mm,'SISTEMA 21 / MASMORRAS / PILOTO 03 / VERSOS')
    for i,ident in enumerate(DATA['piloto']):
        col=i%3;row=i//3
        x=startx+(2-col)*(W+gx);y=starty+(2-row)*(H+gy)
        draw_back(c,BYID[ident],x,y);crop_marks(c,x,y)
        duplex_map.append({'id':ident,'frente':{'linha':row+1,'coluna':col+1},'verso':{'linha':row+1,'coluna':3-col},'regra_no_verso':needs_back(BYID[ident])})
    c.setFont('Body',6);c.setFillColor(HexColor('#454545'))
    c.drawString(startx,5.5*mm,'Versos com colunas em ordem inversa para impressão duplex pela borda longa. Texto em orientação normal.')
    c.showPage();c.save();return out

def guide_pdf():
    out=ROOT/'pdf/Guia_Visual_Piloto_v03_Simbolos.pdf'
    c=canvas.Canvas(str(out),pagesize=A4);c.setTitle('Sistema 21 - guia visual do piloto');pw,ph=A4
    c.setNamedCB('fatigue_symbols',fatigue_callback)
    dark=HexColor('#1C242B');gold=HexColor('#9C7843')
    def head(title,sub,num):
        c.setFillColor(dark);c.rect(0,ph-41*mm,pw,41*mm,fill=1,stroke=0)
        c.setFillColor(HexColor('#D5B27D'));c.setFont('BodyBold',9);c.drawString(17*mm,ph-12*mm,'SISTEMA 21 / MASMORRAS')
        c.setFillColor(HexColor('#FFFFFF'));c.setFont('Title',20);c.drawString(17*mm,ph-24*mm,title)
        c.setFont('Body',9);c.setFillColor(HexColor('#E1D7C5'));c.drawString(17*mm,ph-33*mm,sub)
        c.setFillColor(dark);c.setFont('Body',8);c.drawRightString(pw-17*mm,12*mm,str(num))
    def block(title,text,x,y,width=176*mm):
        c.setFillColor(gold);c.setFont('BodyBold',11);c.drawString(x,y,title)
        p,h=para(text,width,10,14,dark);p.drawOn(c,x,y-6*mm-h)
        return y-6*mm-h-10*mm
    head('Uma coleção, uma identidade','Direção de arte e modelo de impressão - piloto de nove equipamentos',1)
    y=ph-54*mm
    y=block('Direção de arte','Fantasia medieval sombria, equipamentos isolados, materiais críveis e sinais de uso. Luz quente e recorte frio discreto. A raridade aparece no acabamento e no contorno da carta; o objeto continua legível em tamanho pequeno.',17*mm,y)
    y=block('Estrutura e símbolos','Gotas laranja indicam custos de Fadiga; no rodapé, uma gota junto ao número indica o limite da carta. O símbolo de cartas com uma gota identifica Conjuração no Grimório: a fadiga das magias pode ir para outra carta ou item com espaço. Dados e tags têm campos próprios; suas definições ficam no livro. Corpo mínimo: Arial, 8 pt. Ícones vetoriais, nítidos na impressão.',17*mm,y)
    y=block('Frente e verso nas cartas densas','Quando o texto deixaria menos de 28 mm de altura para a imagem, a frente fica com arte, dados, requisitos e tags. As habilidades completas vão para o verso, com nome e ID repetidos. No piloto, isso se aplica à Corrente de Caça, ao Scutum da Legião e ao Grimório do Fogo. A carta de apoio foi substituída pelo verso do próprio item.',17*mm,y)
    for i,ident in enumerate(['EQ-001','EQ-046','EQ-139']):
        image_fit(c,ROOT/BYID[ident]['imagem'],(18+i*62)*mm,y-47*mm,52*mm,44*mm)
        c.setFillColor(dark);c.setFont('BodyBold',8);c.drawCentredString((44+i*62)*mm,y-52*mm,BYID[ident]['nome'])
    c.showPage()
    head('Conteúdo e próxima etapa','Decisões do autor registradas em 26/10/2026',2)
    y=ph-54*mm
    y=block('Três decisões fechadas','Respiração Flamejante: resistência 2 a Gelo durante a cena. A Runa de Fogo mantém a opção de remover uma ficha de Gelo; essa ficha reduz o movimento em 1 e estará no manual. O Scutum mantém a proteção contra flanqueamento, que será explicado no manual.',17*mm,y)
    y=block('O que este piloto valida','Leitura em tamanho real, hierarquia dos dados, tamanho dos símbolos/tags, recorte das artes, contraste e equilíbrio entre texto e imagem. São nove itens de teste dentro de um catálogo de 156. A amostra não equivale a um playtest de equilíbrio de todos os equipamentos.',17*mm,y)
    y=block('Impressão frente e verso','Primeira página A4: nove frentes de 63 × 88 mm. Segunda página: os nove versos, em colunas invertidas para virar pela borda longa. Imprimir em 100%, sem ajustar à página. As cartas curtas conservam suas habilidades na frente e recebem verso de identificação. Fazer uma folha de teste para conferir o alinhamento da impressora.',17*mm,y)
    y=block('Critério para seguir para o restante','Avaliar esta página-piloto e ajustar uma vez o padrão visual. Com o modelo aceito, produzir as 147 artes restantes em lotes e resolver as pendências dos demais textos antes de fechar a edição completa. As artes, os prompts e os dados já ficam separados para reconstruir o PDF sem gerar imagens novamente.',17*mm,y)
    c.showPage();c.save();return out

def main():
  if '--measure' in sys.argv:
    result=[]
    for card in DATA['cartas']:
        dense=needs_back(card)
        p,h,size=back_paragraph(card) if dense else (None,0,8)
        result.append({'id':card['id'],'modo':'frente_verso' if dense else 'frente_unica','verso_cabe':h<=back_text_top(card)-BACK_BOTTOM,'font_verso_pt':size if dense else None,'altura_texto_verso_pt':round(h,1),'altura_arte_original_mm':round(layout(card)[4]/mm,1)})
    (ROOT/'dados/classificacao_layout.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'duplas':sum(r['modo']=='frente_verso' for r in result),'simples':sum(r['modo']=='frente_unica' for r in result),'versos_a_revisar':[r['id'] for r in result if not r['verso_cabe']],'piloto_duplas':[r['id'] for r in result if r['modo']=='frente_verso' and r['id'] in DATA['piloto']]},ensure_ascii=False))
  else:
    for ident in DATA['piloto']:assert (ROOT/BYID[ident]['imagem']).is_file(),ident
    files=[pilot_pdf(),guide_pdf()]
    (ROOT/'dados/verificacao_diagramacao_v03.json').write_text(json.dumps({'medidas':metrics,'imposicao_duplex':duplex_map,'simbolos':symbol_usage},ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'pdfs':[str(p) for p in files],'frentes':9,'versos':9,'font_min_pt':8},ensure_ascii=False))

if __name__=='__main__':main()
