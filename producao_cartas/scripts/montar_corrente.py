"""Monta somente a Corrente de Caça, com a arte v02 e as regras aprovadas."""
import json
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
import montar_piloto as model

ROOT=model.ROOT
CARD=model.BYID['EQ-156']
assert CARD['imagem']=='artes/piloto/EQ-156_v02.png'
assert CARD['campos']['Limite de Fadiga']=='2'
assert CARD['diagramacao']=='frente_verso'

def build(print_sheet=False):
    filename='Corrente_de_Caca_v02_A4_Impressao.pdf' if print_sheet else 'Corrente_de_Caca_v02_Frente_Verso.pdf'
    output=ROOT/'pdf'/filename
    page_size=A4 if print_sheet else (model.W,model.H)
    c=canvas.Canvas(str(output),pagesize=page_size)
    c.setTitle('Corrente de Caça - '+('A4 para impressão' if print_sheet else 'frente e verso 63 x 88 mm'))
    c.setAuthor('Sistema 21 / Masmorras')
    c.setNamedCB('fatigue_symbols',model.fatigue_callback)
    positions=[]
    for index,face in enumerate(['FRENTE','VERSO']):
        x=(page_size[0]-model.W)/2
        y=(page_size[1]-model.H)/2
        if print_sheet:
            c.setFillColor(HexColor('#454545'));c.setFont('BodyBold',11)
            c.drawCentredString(page_size[0]/2,y+model.H+15*mm,'CORRENTE DE CAÇA / '+face)
            c.setFont('Body',8)
            c.drawCentredString(page_size[0]/2,y-12*mm,'63 × 88 mm / imprimir em 100%, sem ajustar à página')
            c.drawCentredString(page_size[0]/2,y-18*mm,'Frente e verso: virar pela borda longa. Conferir uma impressão de teste.')
        if index==0:model.draw_card(c,model.front_of(CARD),x,y)
        else:model.draw_back(c,CARD,x,y)
        if print_sheet:model.crop_marks(c,x,y)
        positions.append({'face':face,'x_pt':x,'y_pt':y,'largura_pt':model.W,'altura_pt':model.H})
        c.showPage()
    c.save()
    assert abs(positions[1]['x_pt']-(page_size[0]-positions[0]['x_pt']-model.W))<.001
    return {'arquivo':str(output),'paginas':2,'pagina_mm':[round(v/mm,3) for v in page_size],'posicoes':positions}

if __name__=='__main__':
    files=[build(),build(True)]
    report={'id':'EQ-156','arte':CARD['imagem'],'corpo_verso_pt':model.back_paragraph(CARD)[2],
            'medidas':model.metrics,'simbolos':model.symbol_usage,'arquivos':files}
    (ROOT/'dados/verificacao_corrente_v02.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'pdfs':[f['arquivo'] for f in files],'arte':CARD['imagem'],'texto_verso_pt':report['corpo_verso_pt']},ensure_ascii=False))
