"""Audita a expansão contra os PDFs e as artes entregues na v05."""
import json, hashlib, zipfile
from pathlib import Path
from PIL import Image
from pypdf import PdfReader

ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'dados/catalogo_cartas.json').read_text(encoding='utf-8'))
cards=data['cartas']; assert len(cards)==170
tag_ids={61,63,68,71,72,75,76};text_ids={64,131,137}
expected_ids={f'EQ-{i:03d}' for i in tag_ids|text_ids}
expected_pages=sorted(p for i in tag_ids|text_ids for p in (2*i-1,2*i))
expected_a4=[13,14,15,16,17,18,29,30,31,32,35,36]
with zipfile.ZipFile(ROOT/'Sistema21_156_Artes_e_Dados_v05.zip') as z:
    old=json.loads(z.read('dados/catalogo_cartas.json'))['cartas']
    altered=[]
    for before,after in zip(old,cards[:156]):
        assert before['id']==after['id']
        if before!=after:altered.append(before['id'])
        assert before['imagem']==after['imagem']
        assert z.read(before['imagem'])==(ROOT/after['imagem']).read_bytes(),before['id']
    assert set(altered)==expected_ids,altered

text_changes={}
for kind,oldcount,newcount,expected in [('Cartas',312,340,expected_pages),('A4',36,38,expected_a4)]:
    a=PdfReader(ROOT/f'pdf/Sistema21_Equipamentos_156_{kind}_v05.pdf')
    b=PdfReader(ROOT/f'pdf/Sistema21_Equipamentos_170_{kind}_v06.pdf')
    assert len(a.pages)==oldcount and len(b.pages)==newcount
    changed=[i+1 for i in range(oldcount) if a.pages[i].extract_text()!=b.pages[i].extract_text()]
    assert changed==expected,(kind,changed,expected)
    text_changes[kind]=changed

visual_changes={}
for folder,prefix,count,expected in [('individuais','carta',312,expected_pages),('colecao','a4',36,expected_a4)]:
    prev=ROOT/f'previews/{folder}_v05'; current=ROOT/f'previews/{folder}_v06'
    changed=[]
    for i in range(1,count+1):
        name=f'{prefix}-{i:03d}.png' if folder=='individuais' else f'{prefix}-{i:02d}.png'
        with Image.open(prev/name) as a,Image.open(current/name) as b:
            if a.size!=b.size or a.tobytes()!=b.tobytes():changed.append(i)
    assert changed==expected,(folder,changed,expected)
    visual_changes[folder]=changed

assert len(list((ROOT/'previews/individuais_v06').glob('carta-*.png')))==340
assert len(list((ROOT/'previews/colecao_v06').glob('a4-*.png')))==38
registry=json.loads((ROOT/'dados/artes_pocoes_v06.json').read_text(encoding='utf-8'))
assert len(registry)==14
for item in registry:
    assert hashlib.sha256((ROOT/item['arquivo']).read_bytes()).hexdigest()==item['sha256']
assert sum('Poção' in c['tags'] for c in cards)==21
result={'versao':'v06','base':'v05','itens':170,'pocoes':21,'novas_artes':14,'artes_anteriores_preservadas':156,'itens_anteriores_alterados':altered,'alteracoes_textuais':text_changes,'alteracoes_visuais':visual_changes,'paginas_renderizadas':378,'demais_paginas_identicas':True,'corrente_e_gladio_preservados':True,'qa_geral':'dados/qa_colecao_v06.json','inspecao_visual':'Pendente de inspeção final das cartas renderizadas.'}
(ROOT/'dados/qa_expansao_final_v06.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
