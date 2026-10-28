"""Registra os PNGs nativos sem transformar nem substituir as artes anteriores."""
import json, shutil, hashlib
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
def read(name):return json.loads((ROOT/'dados'/name).read_text(encoding='utf-8'))
def write(name,value):(ROOT/'dados'/name).write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding='utf-8')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

data=read('catalogo_cartas.json'); before=read('catalogo_cartas_antes_producao_v06.json')
extra=read('itens_adicionais.json'); jobs=read('geracoes_pocoes_v06.json')
assert len(jobs)==14
registry=[]
for job in jobs:
    source=Path(job['origem']); target=ROOT/job['arquivo']
    target.parent.mkdir(parents=True,exist_ok=True)
    if target.exists():assert sha(source)==sha(target)
    else:shutil.copy2(source,target)
    im=Image.open(target)
    assert im.mode=='RGBA', (job['id'],im.mode)
    alpha=im.getchannel('A'); bounds=alpha.point(lambda p:255 if p>=64 else 0).getbbox()
    assert alpha.getextrema()[0]==0 and alpha.getextrema()[1]>=250
    w,h=im.size
    assert all(alpha.getpixel(p)<=4 for p in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)])
    registry.append({'id':job['id'],'arquivo':job['arquivo'],'origem':str(source),'sha256':sha(target),'tamanho_px':list(im.size),'modo':im.mode,'bbox_alpha_64':bounds,'ferramenta':'image_gen.imagegen integrada','modo_ferramenta':'geração nova, fundo transparente','qa_visual':'frasco inteiro, sem texto, eixo reto, estilo aprovado para diagramação'})
    for cards in [data['cartas'],extra]:
        card=next(c for c in cards if c['id']==job['id'])
        card['imagem']=job['arquivo'];card['estado_arte']='concluida'
assert data['cartas'][:156]==before['cartas'][:156]
assert len(data['cartas'])==170 and all((ROOT/c['imagem']).is_file() for c in data['cartas'])
write('catalogo_cartas.json',data);write('itens_adicionais.json',extra);write('artes_pocoes_v06.json',registry)
state=read('estado_producao.json');state.update(artes_geradas=170,artes_restantes=0,novos_itens_pendentes_arte=[],foco_atual='14 poções ilustradas. Montagem e verificação dos PDFs v06 com 170 itens.')
write('estado_producao.json',state)
print(json.dumps({'registradas':len(registry),'artes_totais':170,'anteriores_preservadas':156,'imagens':[{'id':r['id'],'px':r['tamanho_px'],'bbox':r['bbox_alpha_64']} for r in registry]},ensure_ascii=False))
