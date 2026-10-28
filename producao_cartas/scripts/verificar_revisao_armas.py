"""Comparar o escopo visual e os textos de duas versões da coleção."""
import argparse
import hashlib
import json
from pathlib import Path
from pypdf import PdfReader

parser=argparse.ArgumentParser()
parser.add_argument('--version',default='v02')
parser.add_argument('--baseline',default='v01')
args=parser.parse_args()
ROOT=Path(__file__).resolve().parents[1]
data=ROOT/'dados'
revised=json.loads((data/'artes_revisadas.json').read_text(encoding='utf-8'))
current=json.loads((data/'catalogo_cartas.json').read_text(encoding='utf-8'))['cartas']
previous=json.loads((data/f'catalogo_cartas_antes_revisao_armas_{args.version}.json').read_text(encoding='utf-8'))['cartas']
assert len(current)==len(previous)==156
ids=set()
for old,new in zip(previous,current):
    assert old['id']==new['id']
    for key in ['nome','categoria','campos','tags','habilidade','diagramacao']:
        assert old.get(key)==new.get(key),(new['id'],key)
    if old['imagem']!=new['imagem']:ids.add(new['id'])
assert ids and ids<={r['id'] for r in revised}
assert 'EQ-023' not in ids and 'EQ-156' not in ids

total=0
for kind,count in [('A4',36),('Cartas',312)]:
    old=PdfReader(ROOT/f'pdf/Sistema21_Equipamentos_156_{kind}_{args.baseline}.pdf')
    new=PdfReader(ROOT/f'pdf/Sistema21_Equipamentos_156_{kind}_{args.version}.pdf')
    assert len(old.pages)==len(new.pages)==count
    for i,(a,b) in enumerate(zip(old.pages,new.pages),1):
        assert a.extract_text()==b.extract_text(),(kind,i)
        total+=1
    if kind=='A4':
        assert 'Corrente de Caça' in new.pages[34].extract_text()
        assert 'Corrente de Caça' in new.pages[35].extract_text()

digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
changed={}
for folder,prefix,count in [('colecao','a4-',36),('individuais','carta-',312)]:
    olddir=folder if args.baseline=='v01' else folder+'_'+args.baseline
    newdir=folder+'_'+args.version
    files=sorted((ROOT/'previews'/olddir).glob(prefix+'*.png'))
    assert len(files)==count
    assert len(list((ROOT/'previews'/newdir).glob(prefix+'*.png')))==count
    changed[folder]=[f.name for f in files if digest(f)!=digest(ROOT/'previews'/newdir/f.name)]
expected_a4={2*((int(id[3:])-1)//9)+1 for id in ids}
assert set(changed['colecao'])=={f'a4-{i:02d}.png' for i in expected_a4},changed
assert set(changed['individuais'])=={f'carta-{2*int(id[3:])-1:03d}.png' for id in ids},changed
qa={'versao':args.version,'base_comparacao':args.baseline,'revisadas_nesta_versao':sorted(ids),
    'total_revisadas_acumulado':len(revised),'campos_mecanicos_preservados':True,
    'paginas_com_texto_identico':total,'paginas_renderizadas':total,
    'frentes_individuais_alteradas':len(ids),'paginas_A4_alteradas':sorted(expected_a4),
    'todos_versos_visualmente_identicos':True,'gladio_visualmente_identico':True,
    'corrente_preservada_e_presente':True,'corrente_paginas_A4':[35,36],
    'alteracoes_renderizadas':changed}
(data/f'qa_revisao_armas_{args.version}.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
collection=json.loads((data/f'qa_colecao_{args.version}.json').read_text(encoding='utf-8'))
collection.update(paginas_renderizadas=total,artes_revisadas=sorted(r['id'] for r in revised),
                  texto_identico_base=args.baseline,corrente_paginas_A4=[35,36])
(data/f'qa_colecao_{args.version}.json').write_text(json.dumps(collection,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'textos_iguais':total,'alteradas':changed,'resultado':'aprovado'},ensure_ascii=False))

