import sys,json
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
import montar_colecao as book
m=book.m;book.load_assets(False)
path=book.ROOT/'tmp/pdfs/Prova_Interna_Lote_v01.pdf'
path.parent.mkdir(parents=True,exist_ok=True)
c=book.create_canvas(path,A4,'Prova interna de artes e versos')
pw,ph=A4;gap=3*mm;sx=(pw-3*m.W-2*gap)/2;sy=(ph-3*m.H-2*gap)/2
cards=[x for x in book.CARDS if x.get('imagem') and (book.ROOT/x['imagem']).is_file()]
for offset in range(0,len(cards),9):
 c.setFont('Body',7);c.setFillColor(HexColor('#444444'));c.drawString(sx,ph-6*mm,'PROVA DE ARTES / '+str(offset//9+1))
 for i,card in enumerate(cards[offset:offset+9]):m.draw_card(c,m.front_of(card),sx+i%3*(m.W+gap),sy+(2-i//3)*(m.H+gap))
 c.showPage()
ids=['EQ-140','EQ-142','EQ-154','EQ-155','EQ-139','EQ-156','EQ-059','EQ-060','EQ-080']
for i,id in enumerate(ids):book.back(c,m.BYID[id],sx+i%3*(m.W+gap),sy+(2-i//3)*(m.H+gap))
c.showPage();c.save()
print(json.dumps({'pdf':str(path),'artes':len(cards),'paginas':(len(cards)+8)//9+1},ensure_ascii=False))
