import json,sys,shutil,hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ident,source=sys.argv[1:3]
version=sys.argv[sys.argv.index('--version')+1] if '--version' in sys.argv else 'v02'
jobs=json.loads((ROOT/f'dados/prompts_revisao_armas_{version}.json').read_text(encoding='utf-8'))['artes']
job=next(j for j in jobs if j['id']==ident)
src=Path(source);dst=ROOT/job['arquivo'];dst.parent.mkdir(parents=True,exist_ok=True)
if dst.exists():assert hashlib.sha256(dst.read_bytes()).digest()==hashlib.sha256(src.read_bytes()).digest(),'Usar nova versão'
else:shutil.copy2(src,dst)
with Image.open(dst) as im:im.verify()
with Image.open(dst) as im:
    assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0
    meta={'id':ident,'nome':job['nome'],'arquivo':job['arquivo'],'origem':str(src),'substitui':job['referencia'],'dimensoes':list(im.size),'modo':im.mode,'alpha':im.getchannel('A').getextrema(),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'status':'revisao_visual_pendente'}
folder=ROOT/'dados/revisao_armas';folder.mkdir(parents=True,exist_ok=True)
(folder/f'{dst.stem}.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(meta,ensure_ascii=False))
