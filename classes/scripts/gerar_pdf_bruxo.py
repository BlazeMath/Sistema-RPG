"""Cartas imprimíveis do Bruxo, a partir do catálogo v03 autorizado."""
from pathlib import Path
import json, html, re, hashlib
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
import pymupdf

ROOT=Path(__file__).resolve().parents[2]
DATA=ROOT/'classes/dados/bruxo'
OUT=ROOT/'output/pdf/Bruxo_Cartas_v01.pdf'
TMP=ROOT/'tmp/pdfs/bruxo_cartas_v01'
OUT.parent.mkdir(parents=True,exist_ok=True);TMP.mkdir(parents=True,exist_ok=True)
read=lambda n:json.loads((DATA/n).read_text(encoding='utf-8'))
P=read('novos_pactos_v03.json')['patronos'];G=read('habilidades_gerais_v03.json')['cartas'];R=read('regras_propostas_lote_v03.json')
INTERCESSAO='2 Pactos, exile esta carta: após resolver a falha de um ataque da habilidade inicial desse pacto, conjure imediatamente a mesma face, se ainda revelada e com alvos e condições válidos. Pague novamente todos os recursos e aprimoramentos escolhidos, sem outra ação ou Reação; o defensor faz nova defesa. A primeira falha, seus custos e efeitos permanecem. Se for magia de Reação, esta é a única repetição autorizada na janela original, sem novo gatilho, e a exceção ao limite de uma utilização por ataque. Esta carta fica indisponível pelo resto da cena.'
for name,file in [('R','arial.ttf'),('B','arialbd.ttf'),('I','ariali.ttf')]:pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file))
W,H=A4; INK=colors.HexColor('#25212c'); MUTED=colors.HexColor('#655e6e'); ACC=colors.HexColor('#694484'); LINE=colors.HexColor('#bfb4c6')
PALETTE=['#a04928','#583981','#50734d','#9c7426','#316c83','#6c526e','#7b4e39','#38737e','#78537e','#43758a']
page=0; manifest=[]; layout=[]; text_checks=[]; backgrounds=[]
C=canvas.Canvas(str(OUT),pagesize=A4,pageCompression=1)
C.setTitle('Sistema 21 - Cartas do Bruxo');C.setAuthor('Sistema 21');C.setSubject('10 pactos e 18 habilidades gerais - catálogo v03')

def clean(s):
 return str(s).replace('\u2011','-').replace('\u2013','-').replace('\u2014','-').replace('\u00a0',' ')
def para(s,sz=9,leading=None,bold=False):
 return Paragraph(html.escape(clean(s)).replace('\n','<br/>'),ParagraphStyle('p',fontName='B' if bold else 'R',fontSize=sz,leading=leading or sz*1.18,textColor=INK,spaceAfter=0))
def drawp(s,x,top,w,sz=9,bold=False):
 p=para(s,sz,bold=bold);_,h=p.wrap(w,9999);p.drawOn(C,x,top-h);return top-h
def newpage(title,sub=''):
 global page
 if page:C.showPage()
 page+=1;C.setFillColor(ACC);C.setFont('B',11);C.drawString(20,H-23,clean(title))
 if sub:C.setFillColor(MUTED);C.setFont('R',7);C.drawString(20,H-34,clean(sub))
 C.setFillColor(MUTED);C.setFont('R',6.6);C.drawString(20,13,'SISTEMA 21 | Bruxo | Catálogo v03 | 28/10/2026');C.drawRightString(W-20,13,str(page))
def fit_blocks(blocks,w,h,minsz=8.2,maxsz=9.5):
 sz=maxsz
 while sz>=minsz-.001:
  used=0;render=[]
  for label,text in blocks:
   lp=para(label.upper(),max(6.5,sz-.6),bold=True);lh=lp.wrap(w,9999)[1]
   bp=para(text,sz);bh=bp.wrap(w,9999)[1]
   render.append((lp,lh,bp,bh));used+=lh+2+bh+7
  if used<=h:return sz,used,render
  sz=round(sz-.1,2)
 raise ValueError(f'Texto não cabe: {h:.1f}pt / '+str([(a,len(b)) for a,b in blocks]))
def card(x,top,w,h,ident,title,meta,blocks,color=ACC,badge=None,minsz=8.2,maxsz=9.5,foot='',kind=''):
 y=top-h;pad=9
 C.setStrokeColor(LINE);C.setLineWidth(.65);C.setFillColor(colors.white);C.roundRect(x,y,w,h,7,fill=1,stroke=1)
 C.setFillColor(color);C.roundRect(x,y+h-12,w,12,7,fill=1,stroke=0);C.rect(x,y+h-14,w,7,fill=1,stroke=0)
 C.setFillColor(colors.white);C.setFont('B',6.2);C.drawString(x+pad,top-9,clean(ident))
 tw=w-2*pad-(27 if badge else 0)
 tp=para(title,11 if w>200 else 10.1,bold=True);th=tp.wrap(tw,9999)[1]
 tp.drawOn(C,x+pad,top-21-th)
 if badge:
  C.setFillColor(color);C.circle(x+w-21,top-31,12,fill=1,stroke=0);C.setFillColor(colors.white);C.setFont('B',8);C.drawCentredString(x+w-21,top-30,clean(badge));C.setFont('R',5);C.drawCentredString(x+w-21,top-37,'XP')
 mt=top-27-th
 mp=para(meta,6.8);mh=mp.wrap(w-2*pad,9999)[1];mp.drawOn(C,x+pad,mt-mh)
 bodytop=mt-mh-7;bottom=y+(23 if foot else 10);available=bodytop-bottom
 sz,used,render=fit_blocks(blocks,w-2*pad,available,minsz,maxsz)
 cursor=bodytop
 for lp,lh,bp,bh in render:
  lp.drawOn(C,x+pad,cursor-lh);cursor-=lh+2
  bp.drawOn(C,x+pad,cursor-bh);cursor-=bh+7
 assert cursor+7>=bottom-.5,(ident,cursor,bottom)
 if foot:
  C.setStrokeColor(LINE);C.line(x+pad,y+20,x+w-pad,y+20)
  C.setFillColor(color);C.setFont('B',7);C.drawString(x+pad,y+9,clean(foot))
 # Small outside crop marks; the rounded border is the final cut contour.
 C.setStrokeColor(LINE);C.setLineWidth(.35)
 for xx,yy,dx,dy in [(x,y,-3,0),(x,y,0,-3),(x+w,y,3,0),(x+w,y,0,-3),(x,top,-3,0),(x,top,0,3),(x+w,top,3,0),(x+w,top,0,3)]:C.line(xx,yy,xx+dx,yy+dy)
 manifest.append({'id':ident,'titulo':title,'pagina':page,'tipo':kind,'tamanho_mm':[round(w/mm,2),round(h/mm,2)],'fonte_pt':sz,'caixa':[x,H-top,x+w,H-y]})
 for _,text in blocks:text_checks.append((page,text,ident))

def refpage(title,blocks):
 newpage(title,'Regras de referência - não são cartas para recortar')
 top=H-52
 for label,txt in blocks:
  pp=para(txt,9.4);height=pp.wrap(W-52,9999)[1]+30
  if top-height<32:
   newpage(title+' - continuação','Regras de referência - não são cartas para recortar');top=H-52
  top=drawp(label,26,top,W-52,10,True)-4
  top=drawp(txt,26,top,W-52,9.4)-14

newpage('Cartas do Bruxo','10 pactos | 18 habilidades gerais | Efeitos da Fênix preservados')
top=H-77
top=drawp('Poder emprestado. Compromissos reais.',28,top,W-56,25,True)-18
top=drawp('Coleção de trabalho para impressão e teste. Conteúdo mecânico do catálogo v03, com a revisão autorizada aplicada.',28,top,W-56,11)-20
intro=[('Conteúdo','Cada patrono tem três cartas: herói, contrato do pacto e habilidade inicial A/B. Herói e contrato incluem versos de consulta. As habilidades gerais são nove pares A/B de 1 XP, seis opções de meia carta de 1/2 XP e três pares A/B de 2 XP.'),('Tamanhos e montagem','Herói e pacto: 90,2 x 129,1 mm, conforme a moldura das cartas de herói existentes. Habilidades: 63 x 88 mm. Imprima em tamanho real (100%), sem ajustar à página. Recorte pelas molduras. Frente e verso estão lado a lado ou identificados na mesma folha; este arquivo não é uma imposição de frente e verso automática. Una os lados correspondentes pelo código.'),('Versos de consulta','Os versos de herói e pacto não são novas habilidades de lado B. Reúnem regras e favores menores do mesmo vínculo. Consultá-los não representa uma virada de habilidade. O favor menor só fica disponível se uma habilidade como Pacto Menor o conceder.'),('Fênix','Os efeitos aprovados foram mantidos. Cobrança, consequência e reparação continuam em aberto. O PDF não define novos valores, alcance ou ação para os pontos que já estavam pendentes.'),('Estado de teste','A revisão de regras está aplicada; o equilíbrio numérico ainda depende de partidas. Os textos extensos foram preservados. IDs permitem conferir cada face com o catálogo.')]
for label,txt in intro:
 top=drawp(label.upper(),28,top,W-56,9,True)-3;top=drawp(txt,28,top,W-56,9.5)-15
index_start=page+1

# One page per patron: front/back of the two hero-sized cards.
LW,LH=255.8,366.0
xs=[(W-2*LW-8)/2,(W-2*LW-8)/2+LW+8]
tops=[H-45,H-45-LH-9]
for idx,p in enumerate(P):
 col=colors.HexColor(PALETTE[idx]);newpage(p['nome'],p['patrono']+' | Herói e contrato: una frente e verso pelo código')
 hero=p['heroi'];level='A definir' if hero['limite_fadiga'] is None else str(hero['limite_fadiga'])
 card(xs[0],tops[0],LW,LH,p['id']+'-H | FRENTE',p['patrono'],'Bruxo | Herói | Tag Pacto',[(lab,hero[key]) for lab,key in [('Passiva','passiva'),('Ativada','ativada'),('Desencadeada','desencadeada'),('Crítico','critico')]],col,foot='LIMITE DE FADIGA: '+level,kind='heroi_frente')
 tags=' | '.join(p['tags'])
 hb=[('Identidade',p['identidade']),('Favor menor - exige Pacto Menor',p['menor']),('Cobrança do vínculo menor',p['cobranca_menor'])]
 if p.get('pendencias'):hb.append(('Em aberto',' '.join(p['pendencias'])))
 card(xs[1],tops[0],LW,LH,p['id']+'-H | VERSO DE CONSULTA',p['nome'],'Consulta do herói | '+tags,hb,col,minsz=8.2,kind='heroi_consulta')
 # The tracker is a dedicated block with printable empty boxes.
 contract=p['pacto']
 front=[('Nível do pacto','[ 1 ]   [ 2 ]   [ 3 ]   [ 4 ]   [ 5 ]'),('Reserva','Começo da cena: 2 x nível em fichas de Pacto. Reserva própria nesta carta; descarte todas ao fim da cena. O mestre decide a progressão conforme o cumprimento.'),('Bônus por cumprimento',contract['beneficio']),('Cobrança',contract['cobranca']),('Habilidade inicial',contract['habilidade_inicial'])]
 card(xs[0],tops[1],LW,LH,p['id']+'-P | FRENTE',p['nome'],'Bruxo | Pacto | '+tags,front,col,minsz=8.2,kind='pacto_frente')
 back=[]
 if contract.get('escolha'):back.append(('Escolha do protegido',contract['escolha']))
 back += [('Descumprimento',contract['quebra']),('Reparação',contract['reparacao'])]
 if idx:
  back += [('Enquanto suspenso','Não ganhe nem gaste Pacto deste vínculo. Ficam inativos o favor menor, ativada, desencadeada, crítico e aprimoramentos concedidos pelo vínculo. Tags e associação permanecem; magias básicas continuam acessíveis para reparar. Efeitos anteriores e custos pagos não são desfeitos. Reparar não repete o ganho inicial da cena.')]
 else:back.append(('Cobrança da Fênix','EM ABERTO. Nenhuma consequência de suspensão dos outros pactos é aplicada automaticamente à Fênix.'))
 card(xs[1],tops[1],LW,LH,p['id']+'-P | VERSO DE CONSULTA',p['nome'],'Contrato | Regras de cumprimento e reparação',back,col,minsz=8.2,kind='pacto_consulta')

# Skills use the established 63 x 88 mm footprint, A/B pairs in adjacent columns.
SW,SH=63*mm,88*mm
sx=[(W-2*SW-14)/2,(W-2*SW-14)/2+SW+14]
st=[H-45-r*(SH+7) for r in range(3)]
def skill_sheet(pairs,title):
 for start in range(0,len(pairs),3):
  newpage(title,'63 x 88 mm | Faces correspondentes lado a lado | Imprimir a 100%')
  for row,pair in enumerate(pairs[start:start+3]):
   for side,item in enumerate(pair):
    if item is None:continue
    ident,name,meta,txt,fat,xp,col,kind=item
    card(sx[side],st[row],SW,SH,ident,name,meta,[('Efeito',txt)],col,badge=xp,minsz=8,maxsz=9.2,foot='LIMITE DE FADIGA: '+str(fat),kind=kind)
initial=[]
for idx,p in enumerate(P):
 pair=[]
 for f in p['habilidade']['lados']:
  extra=''
  if 'conjuracao' in f:extra=' | Conjuração '+('sim' if f['conjuracao'] else 'não')
  if f.get('rapida'):extra+=' | Rápida'
  pair.append((p['id']+'-I | '+f['lado'],f['nome'],'Inicial do pacto | '+', '.join(p['tags'])+extra,f['texto'],f['limite_fadiga'],None,colors.HexColor(PALETTE[idx]),'inicial_'+f['lado']))
 initial.append(pair)
skill_sheet(initial,'Bruxo | Habilidades iniciais dos pactos')
for xp,title in [(1,'Habilidades gerais de 1 XP'),(.5,'Meias cartas de 1/2 XP'),(2,'Habilidades gerais de 2 XP')]:
 pairs=[];halves=[]
 for c in [c for c in G if c['xp']==xp]:
  pair=[]
  for side,f in enumerate(c['lados']):
   code=c['id']+(' | '+('A' if side==0 else 'B') if len(c['lados'])==2 else ' | MEIA')
   txt=INTERCESSAO if c['id']=='BR-X03' and side==0 else f['texto']
   pair.append((code,f['nome'],'Requer Pacto | '+c['grupo'],txt,f['limite_fadiga'],'1/2' if xp==.5 else str(xp),ACC,'geral'))
  if xp==.5:halves+=pair
  else:pairs.append(pair)
 if halves:pairs=[halves[i:i+2] for i in range(0,len(halves),2)]
 skill_sheet(pairs,'Bruxo | '+title)

refpage('Regras do Bruxo | Base e uso dos vínculos',[(f'Base {i+1}',s) for i,s in enumerate(R['base_confirmada'])]+[(f'Uso {i+1}',s) for i,s in enumerate(R['convencoes_propostas'])])
refpage('Regras do Bruxo | Revisão aplicada',[(f'Regra {i+1}',s) for i,s in enumerate(R['ajustes_aplicados'])])
refpage('Consulta | Intercessão do Patrono', [('Texto integral do catálogo v03',next(c for c in G if c['id']=='BR-X03')['lados'][0]['texto']),('Diagramação da carta','A carta BR-X03 lado A usa uma redação condensada dos mesmos efeitos para preservar a legibilidade no formato 63 x 88 mm. O texto integral acima permanece como referência. Nenhum custo, gatilho, limite ou consequência foi alterado.')])
C.save()

doc=pymupdf.open(OUT)
def norm(t):return re.sub(r'\s+','',clean(t))
missing=[]
for pn,txt,ident in text_checks:
 if norm(txt) not in norm(doc[pn-1].get_text()):missing.append(ident)
assert not missing,('Texto incompleto',missing)
assert sum(x['tipo'].startswith('inicial_') for x in manifest)==20
assert sum(x['tipo']=='geral' for x in manifest)==30
assert sum(x['tipo']=='heroi_frente' for x in manifest)==10
assert sum(x['tipo']=='pacto_frente' for x in manifest)==10
assert len(manifest)==90
qa={'data':'2026-10-28','pdf':str(OUT.relative_to(ROOT)),'paginas':len(doc),'faces_impressas':90,'herois':10,'pactos':10,'iniciais_AB':10,'gerais_entradas':18,'gerais_faces':30,'fonte_minima_pt':min(x['fonte_pt'] for x in manifest),'verificacao_textos':not missing,'fenix_catalogo_preservado':P[0]==read('novos_pactos_v02.json')['patronos'][0],'redacao_condensada':['BR-X03 A, com texto integral em página de referência'],'manifesto':manifest,'sha256':hashlib.sha256(OUT.read_bytes()).hexdigest()}
writepath=DATA/'verificacao_pdf_bruxo_v01.json';writepath.write_text(json.dumps(qa,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in qa.items() if k!='manifesto'},ensure_ascii=False))
