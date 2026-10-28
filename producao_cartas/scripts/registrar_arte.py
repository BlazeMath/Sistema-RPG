import json,sys,shutil,hashlib
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]/'producao_cartas'
ident,source=sys.argv[1:3]
version=sys.argv[3] if len(sys.argv)>3 else 'v01'
src=Path(source)
dst=ROOT/'artes/piloto'/f'{ident}_{version}.png'
assert src.is_file() and ident.startswith('EQ-')
if dst.exists():
    assert hashlib.sha256(dst.read_bytes()).digest()==hashlib.sha256(src.read_bytes()).digest(),f'Use uma nova versão: {dst}'
else:
    shutil.copy2(src,dst)
with Image.open(dst) as im:
    alpha=im.getchannel('A').getextrema() if 'A' in im.getbands() else None
    meta={'id':ident,'arquivo':str(dst),'origem':str(src),'dimensoes':list(im.size),'modo':im.mode,'alpha':alpha,'status':'piloto_para_avaliacao'}
registry=ROOT/'dados/artes_piloto.json'
data=json.loads(registry.read_text(encoding='utf-8')) if registry.exists() else {}
data[ident]=meta
registry.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(meta,ensure_ascii=False))
