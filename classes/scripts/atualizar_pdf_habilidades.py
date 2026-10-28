"""Aplica as revisões de classe ao PDF original, preservando as demais faces."""
from pathlib import Path
import io, json, re, hashlib, shutil, html
import pymupdf as fitz
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.colors import Color, HexColor
from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'classes/dados/ajustes_cartas_v01.json'
OUT = ROOT / 'output/pdf/Habilidades_Cartas_Atualizadas_v01.pdf'
TMP = ROOT / 'tmp/pdfs/habilidades_atualizadas_v01'
BACKUP = ROOT / 'classes/fontes/Habilidades_Cartas_original_2026-10-27.pdf'
QA = ROOT / 'classes/dados/verificacao_pdf_habilidades_v01.json'
fatigue_usage = []

def normalized(s):
    return ''.join(c for c in s.casefold() if c.isalnum())

def drop(c, x, y, w, h):
    c.saveState(); c.translate(x, y); c.scale(w, h)
    p = c.beginPath(); p.moveTo(.5, 1)
    p.curveTo(.43,.78,.03,.42,.03,.25)
    p.curveTo(.03,-.08,.97,-.08,.97,.25)
    p.curveTo(.97,.42,.57,.78,.5,1); p.close()
    c.setFillColor(HexColor('#FF671F')); c.drawPath(p, fill=1, stroke=0)
    c.restoreState()

def fatigue(c, kind, label):
    count, size = label.split('|'); count=int(count); size=float(size)
    tx=c._curr_tx_info
    for i in range(count):
        drop(c,tx['cur_x']-count*size*.6+i*size*.6,tx['cur_y']-.05*size,size*.49,size*.84)
    fatigue_usage.append(count)

def rich(text, size, accent):
    result=[]
    for line in text.splitlines():
        line=html.escape(line)
        if ':' in line and len(line.split(':',1)[0]) < 95:
            before, after=line.split(':',1)
            before=before.replace('Ação Padrão','AÇÃO PADRÃO')
            match=re.match(r'^(\d+) de Fadiga',before)
            if match:
                n=int(match[1]); symbol='<nobr><font name="Courier" size="%s">'%size+'&#160;'*n+f'</font><onDraw name="fatigue" label="{n}|{size}"/></nobr>'
                before=symbol+before[match.end():]
            line=f'<b><font color="{accent}">{before}:</font></b>{after}'
        result.append(line)
    return '<br/>'.join(result)

def outer_cards(page):
    return [d['rect'] for d in page.get_drawings()
            if d['type']=='s' and 170<d['rect'].width<182 and 240<d['rect'].height<253]

def spans(page, rect):
    return [s for b in page.get_text('dict',clip=rect)['blocks']
            for l in b.get('lines',[]) for s in l['spans']]

def locate(page, card):
    found=[]
    for r in outer_cards(page):
        text=page.get_textbox(r)
        if card['id'] in text and normalized(card['nome']) in normalized(text):
            found.append(r)
    assert len(found)==1, (card['nome'],found)
    r=found[0]; ss=spans(page,r)
    body=[s for s in ss if s['size']>=8 and s['bbox'][1]>r.y0+40 and s['bbox'][1]<r.y1-25]
    assert body,card['nome']
    top=min(s['bbox'][1] for s in body)-1.5
    rect=fitz.Rect(r.x0+7,top,r.x1-6,r.y1-26)
    body_color=next((s['color'] for s in body if 'Bold' not in s['font']),body[0]['color'])
    color=Color(((body_color>>16)&255)/255,((body_color>>8)&255)/255,(body_color&255)/255)
    return r, rect, color, ss

def build():
    patches=json.loads(DATA.read_text(encoding='utf-8'))
    TMP.mkdir(parents=True,exist_ok=True);OUT.parent.mkdir(parents=True,exist_ok=True)
    BACKUP.parent.mkdir(parents=True,exist_ok=True)
    if not BACKUP.exists():
        assert hashlib.sha256((ROOT/'Habilidades_Cartas.pdf').read_bytes()).hexdigest()==patches['sha256_fonte_pdf']
        shutil.copy2(ROOT/'Habilidades_Cartas.pdf',BACKUP)
    assert hashlib.sha256(BACKUP.read_bytes()).hexdigest()==patches['sha256_fonte_pdf']
    edits=list(patches['cartas'])
    edits += [x for x in patches.get('propostas',[]) if x['nome']=='Predador Absoluto']
    # Mesma mecânica esclarecida pelo autor, com redação compacta para a carta.
    for c in edits:
        if c['nome']=='Predador Absoluto':
            c['texto']='No início da cena com este lado revelado, ou ao revelá-lo pela primeira vez na cena, escolha um inimigo visível como alvo da caça.\nAté o fim da cena, coloque o dobro das fichas que seus efeitos colocariam no alvo. Nos efeitos sobre ele calculados pela quantidade de fichas gastas, calcule como se gastasse o dobro, pagando o custo normal. Duplique cada efeito apenas uma vez por esta habilidade.\nNo fim do seu turno, se causou dano ao alvo neste turno, ganhe 1 ficha de Preparo.\nQuando ele morrer, escolha outro inimigo visível.'
    source=fitz.open(BACKUP); dest=fitz.open(BACKUP)
    records=[]; masks={}
    for pn in sorted({c['pagina'] for c in edits}):
        page=dest[pn-1]; original=source[pn-1]
        buffer=io.BytesIO(); cv=canvas.Canvas(buffer,pagesize=tuple(page.rect[2:]),pageCompression=1)
        cv.setNamedCB('fatigue',fatigue)
        pending=[]
        for card in [c for c in edits if c['pagina']==pn]:
            r, rect, color, ss=locate(original,card)
            accent={'Guerreiro':'#FF671F','Clérigo':'#665019','Caçador':'#AEC873','Mago':'#9CBDED','Ladino':'#B9BBC4'}[card['classe']]
            available=rect.height-2
            selected=None
            for step in range(130,79,-1):
                size=step/10
                style=ParagraphStyle('card',fontName='Times-Roman',fontSize=size,leading=size*1.25,textColor=color,spaceAfter=0,spaceBefore=0,splitLongWords=False)
                par=Paragraph(rich(card['texto'],size,accent),style)
                _,height=par.wrap(rect.width-4,1000)
                if height<=available:
                    selected=(par,height,size);break
            assert selected, f"Texto não cabe a 8 pt: {card['nome']}"
            page.add_redact_annot(rect,fill=None,cross_out=False)
            masks.setdefault(pn,[]).append(tuple(rect))
            par,height,size=selected
            usage_before=len(fatigue_usage)
            par.drawOn(cv,rect.x0+2,page.rect.height-rect.y0-height)
            record={'nome':card['nome'],'id':card['id'],'lado':card['lado'],'pagina':pn,'corpo_pt':size,'altura_texto_pt':height,'altura_disponivel_pt':available,'corpo_rect':list(rect),'texto':card['texto'],'custos_simbolizados':fatigue_usage[usage_before:]}
            if card['nome']=='Flecha de Rede':
                footer=[s for s in ss if s['text'].strip()=='1' and s['bbox'][1]>r.y1-25]
                assert len(footer)==1
                s=footer[0]; fr=fitz.Rect(s['bbox']);fr.x0-=.6;fr.x1+=.6;fr.y0-=.3;fr.y1+=.3
                page.add_redact_annot(fr,fill=None,cross_out=False);masks[pn].append(tuple(fr))
                cv.setFillColor(HexColor('#FF671F'));cv.setFont('Times-Bold',s['size'])
                cv.drawRightString(s['bbox'][2],page.rect.height-s['origin'][1],'2')
            records.append(record)
        cv.showPage();cv.save()
        page.apply_redactions(images=0,graphics=1,text=0)
        overlay=fitz.open(stream=buffer.getvalue(),filetype='pdf')
        page.show_pdf_page(page.rect,overlay,0,overlay=True)
    dest.set_metadata({**dest.metadata,'title':'Sistema 21 - Habilidades de Classes - revisão 27/10/2026','subject':'17 faces revisadas; mantém a ordem e as demais cartas da coleção.'})
    dest.save(OUT,garbage=4,deflate=True);dest.close()
    result=fitz.open(OUT);assert len(result)==20
    for rec in records:
        text=result[rec['pagina']-1].get_textbox(fitz.Rect(rec['corpo_rect']))
        # Custos de ativação são desenhados como gotas, tal como no original.
        expected='\n'.join(re.sub(r'^\d+ de Fadiga(?:,\s*)?', '',x) for x in rec['texto'].splitlines())
        assert normalized(text)==normalized(expected),(rec['nome'],text,expected)
    assert len(records)==17 and min(r['corpo_pt'] for r in records)>=8
    # Compara toda a área fora dos trechos alterados para evitar alterações colaterais.
    outside=[]
    for i in range(20):
        before=source[i].get_pixmap(matrix=fitz.Matrix(1,1),alpha=False)
        after=result[i].get_pixmap(matrix=fitz.Matrix(1,1),alpha=False)
        a=Image.frombytes('RGB',(before.width,before.height),before.samples)
        b=Image.frombytes('RGB',(after.width,after.height),after.samples)
        diff=ImageChops.difference(a,b);mask=Image.new('L',a.size,255);draw=ImageDraw.Draw(mask)
        for box in masks.get(i+1,[]):draw.rectangle((int(box[0])-2,int(box[1])-2,int(box[2])+3,int(box[3])+3),fill=0)
        diff=ImageChops.multiply(diff,Image.merge('RGB',(mask,mask,mask)))
        if diff.getbbox():outside.append({'pagina':i+1,'bbox':diff.getbbox()})
    # Prévia de todas as páginas e recortes em resolução de leitura das 17 correções.
    page_imgs=[]
    for i in range(20):
        pix=result[i].get_pixmap(matrix=fitz.Matrix(1,1),alpha=False)
        img=Image.frombytes('RGB',(pix.width,pix.height),pix.samples);img.thumbnail((476,675))
        page_imgs.append(img)
    for group in range(5):
        sheet=Image.new('RGB',(1000,1440),'#e5e5e5');draw=ImageDraw.Draw(sheet)
        for k,img in enumerate(page_imgs[group*4:group*4+4]):
            x=12+(k%2)*500;y=28+(k//2)*715
            sheet.paste(img,(x,y));draw.text((x,y-19),f'Página {group*4+k+1}',fill='black')
        sheet.save(TMP/f'paginas_{group+1}.png')
    crops=[]
    for rec in records:
        card=next(c for c in edits if c['nome']==rec['nome'])
        r,*_=locate(source[rec['pagina']-1],card)
        pix=result[rec['pagina']-1].get_pixmap(matrix=fitz.Matrix(2,2),clip=r,alpha=False)
        crops.append((rec,Image.frombytes('RGB',(pix.width,pix.height),pix.samples)))
    for g in range((len(crops)+5)//6):
        sheet=Image.new('RGB',(1125,1080),'#e5e5e5');draw=ImageDraw.Draw(sheet)
        for k,(rec,img) in enumerate(crops[g*6:g*6+6]):
            x=10+(k%3)*375;y=30+(k//3)*540
            sheet.paste(img,(x,y));draw.text((x,y-20),rec['nome'],fill='black')
        sheet.save(TMP/f'correcoes_{g+1}.png')
    qa={'data':'2026-10-27','fonte_original':BACKUP.relative_to(ROOT).as_posix(),'fonte_sha256':hashlib.sha256(BACKUP.read_bytes()).hexdigest(),'pdf':OUT.relative_to(ROOT).as_posix(),'pdf_sha256':hashlib.sha256(OUT.read_bytes()).hexdigest(),'paginas':len(result),'faces_revisadas':len(records),'registros':records,'diferencas_fora_das_areas_editadas':outside,'texto_integral_das_17_faces_conferido':True,'inspecao_visual':'pendente'}
    QA.write_text(json.dumps(qa,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'pdf':str(OUT),'paginas':20,'faces':len(records),'menor_corpo_pt':min(r['corpo_pt'] for r in records),'diferencas_externas':outside,'fontes':[(r['nome'],r['corpo_pt']) for r in records]},ensure_ascii=False))

if __name__=='__main__':build()
