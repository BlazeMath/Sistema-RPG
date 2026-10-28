import json,sys,shutil,hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ident,source=sys.argv[1:3]
jobs=json.loads((ROOT/'dados/prompts_lote_v01.json').read_text(encoding='utf-8'))
job=next(j for j in jobs if j['id']==ident)
src=Path(source);dst=ROOT/job['arquivo']
assert src.is_file() and src.suffix.lower()=='.png'
if dst.exists():assert hashlib.sha256(dst.read_bytes()).digest()==hashlib.sha256(src.read_bytes()).digest()
else:shutil.copy2(src,dst)
with Image.open(dst) as im:
    im.verify()
with Image.open(dst) as im:
    alpha=im.getchannel('A').getextrema() if 'A' in im.getbands() else None
    meta={'id':ident,'arquivo':job['arquivo'],'origem':str(src),'dimensoes':list(im.size),'modo':im.mode,'alpha':alpha,'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'status':'gerada_a_conferir'}
(ROOT/'dados'/f'{ident}_arte_v01.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(meta,ensure_ascii=False))
