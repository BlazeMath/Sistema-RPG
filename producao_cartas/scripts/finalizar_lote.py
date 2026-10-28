import json,sys,hashlib,zipfile
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'dados/catalogo_cartas.json').read_text(encoding='utf-8'))
jobs=json.loads((ROOT/'dados/prompts_lote_v01.json').read_text(encoding='utf-8'))
records=[];missing=[]
for j in jobs:
    override=ROOT/'dados'/f"override_{j['id']}_v01.json"
    if override.exists():j.update(json.loads(override.read_text(encoding='utf-8')))
    path=ROOT/j['arquivo'];meta=ROOT/'dados'/f"{j['id']}_arte_v01.json"
    if not path.is_file() or not meta.is_file():missing.append(j['id']);continue
    with Image.open(path) as im:
        assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0,(j['id'],im.mode)
    j['status']='gerada';j['ferramenta']='image_gen.imagegen (integrada)'
    record=json.loads(meta.read_text(encoding='utf-8'));records.append(record)
state=json.loads((ROOT/'dados/estado_producao.json').read_text(encoding='utf-8'))
state.update({'etapa':'producao_em_lote' if missing else 'diagramacao_colecao_completa','artes_geradas':9+len(records),'artes_restantes':len(missing),'total_itens':156,'foco_atual':'Produção da coleção completa com o modelo aprovado da Corrente.','aguarda':'Conclusão das artes e conferência dos PDFs completos.','todos_itens_com_verso_de_consulta':True})
state['modelo_corrente']['estado']='aprovado_pelo_autor_para_producao_em_lote'
if '--partial' not in sys.argv:
    assert not missing,missing
    for card in data['cartas']:
        record=next((r for r in records if r['id']==card['id']),None)
        if record:card['imagem']=record['arquivo']
    revision_registry=ROOT/'dados/artes_revisadas.json'
    if revision_registry.exists():
        revisions={r['id']:r for r in json.loads(revision_registry.read_text(encoding='utf-8'))}
        for card in data['cartas']:
            if card['id'] in revisions:card['imagem']=revisions[card['id']]['arquivo']
    data['padrao_versos']='Dados, requisitos e tags repetidos; todas as habilidades integrais no verso. As cartas curtas também conservam a habilidade na frente.'
    (ROOT/'dados/catalogo_cartas.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    (ROOT/'dados/prompts_lote_v01.json').write_text(json.dumps(jobs,ensure_ascii=False,indent=2),encoding='utf-8')
    (ROOT/'dados/artes_lote_v01.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'dados/estado_producao.json').write_text(json.dumps(state,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'total_artes':9+len(records),'novas_salvas':len(records),'restantes':len(missing)},ensure_ascii=False))
