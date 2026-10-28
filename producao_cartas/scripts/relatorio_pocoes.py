"""Relatório de revisão das poções. Não cria PDFs nem imagens."""
import html,json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'dados'
comparison=json.loads((D/'comparacao_pocoes_witcher3_2026-10-27.json').read_text(encoding='utf-8'))
catalog=json.loads((D/'catalogo_cartas.json').read_text(encoding='utf-8'))['cartas']
new=json.loads((D/'itens_adicionais.json').read_text(encoding='utf-8'))
rules=json.loads((D/'regras_pocoes_para_manual.json').read_text(encoding='utf-8'))
sources={s['id']:s for s in comparison['fontes']}
e=lambda value:html.escape(str(value),quote=True)
def card(c):
    rarity=c['categoria'].split('·')[-1].strip()
    fields=' · '.join(f'{e(k)}: {e(v)}' for k,v in c['campos'].items())
    return f'''<article id="{e(c['id'])}"><small>{e(c['id'])} · {e(rarity)}</small>
    <h3>{e(c['nome'])}</h3><p class="reference">Referência: {e(c.get('referencia_witcher3','Item do catálogo anterior'))}</p>
    <p>{fields}</p><p class="ability">{e(c['habilidade'])}</p><details><summary>Nota de adaptação</summary><p>{e(c['revisao'])}</p></details></article>'''
rows=[]
for row in comparison['comparacao']:
    source=sources[row['fonte']]
    ids=' / '.join(f'<a href="#{e(id)}">{e(id)}</a>' for id in row['itens_sistema21'])
    rows.append(f'''<tr><th><a href="{e(source['url'])}">{e(row['origem'])}</a></th>
    <td>{e(row['funcao_origem'])}</td><td>{e(row['decisao'])}</td><td>{ids}</td><td>{e(row['justificativa'])}</td></tr>''')
old_ids={'EQ-061','EQ-063','EQ-068','EQ-071','EQ-072','EQ-075','EQ-076'}
old=[c for c in catalog if c['id'] in old_ids]
updated=[c for c in catalog if c['id'] in {'EQ-064','EQ-131','EQ-137'}]
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sistema 21 — expansão de poções</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f1e8;color:#26251f;font:16px/1.55 system-ui,Segoe UI,sans-serif}
main{max-width:1180px;margin:auto;padding:32px 24px}header{border-bottom:3px solid #9b7433;padding-bottom:20px}
h1{font:700 2.2rem Georgia,serif;margin:.3em 0}h2{margin:2em 0 .8em}h3{margin:.25em 0;color:#40351f}
a{color:#305d43}nav{display:flex;gap:18px;flex-wrap:wrap;margin-top:18px}.status{padding:14px 18px;background:#e2eadf;border-left:4px solid #537551}
.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}article{padding:22px;background:#fffdf8;border:1px solid #d9cdb7;border-radius:10px;scroll-margin-top:15px}
small,.reference{color:#655c4a}.reference{font-size:.9rem}.ability{white-space:pre-line}details{border-top:1px solid #e5dccd;padding-top:12px;font-size:.9rem}
table{border-collapse:collapse;width:100%;background:#fffdf8;font-size:.9rem}td,th{border:1px solid #d9cdb7;padding:12px;text-align:left;vertical-align:top}thead{background:#e9e2d3}.table-wrap{overflow-x:auto}th{min-width:130px}
li{margin:.5em 0}footer{border-top:1px solid #cbbb9c;margin-top:36px;padding-top:20px;font-size:.9rem}
@media(max-width:700px){main{padding:20px 14px}.grid{grid-template-columns:1fr}h1{font-size:1.8rem}}
</style><main><header><small>SISTEMA 21 / MASMORRAS · REVISÃO DE 27/10/2026</small>
<h1>Expansão de poções</h1><p><strong>14 novas poções · 170 itens no catálogo · 7 poções anteriores identificadas.</strong></p>
<div class="status">Mudanças implementadas nos dados. Os PDFs continuam na versão 05 com 156 itens. As 14 novas ilustrações estão pendentes.</div>
<nav><a href="#comparacao">Comparação</a><a href="#novas">Novas poções</a><a href="#anteriores">Poções anteriores</a><a href="#regras">Regras comuns</a><a href="#correcoes">Outras correções</a></nav></header>
<p>Foram comparadas 13 famílias regulares de The Witcher 3 e seis referências especiais. Variantes básica, melhorada e superior foram agrupadas por função. Bear pheromones e Nekker pheromones foram registrados à parte como conteúdo cortado do jogo original. Decoctos de mutagênicos são uma categoria separada e não foram incluídos nesta expansão. Ingredientes e rituais de missão não viraram consumíveis comuns.</p>
<p><strong>Adaptação:</strong> nomes, números, ações, durações e contrapartidas abaixo foram criados para o Sistema 21. São valores iniciais para playtest, e não números originais do videogame ou equilíbrio já comprovado.</p>
<section id="comparacao"><h2>O que já existia e o que foi acrescentado</h2><div class="table-wrap"><table><thead><tr><th>Referência</th><th>Função no jogo</th><th>Decisão</th><th>Itens</th><th>Adaptação ao sistema</th></tr></thead><tbody>'''+''.join(rows)+'''</tbody></table></div></section>
<section id="novas"><h2>As 14 novas poções</h2><div class="grid">'''+''.join(card(c) for c in new)+'''</div></section>
<section id="anteriores"><h2>Poções anteriores preservadas</h2><p>Estas sete cartas receberam apenas a identificação de Poção. Seus efeitos não foram alterados por esta expansão.</p><div class="grid">'''+''.join(card(c) for c in old)+'''</div></section>
<section id="regras"><h2>Regras comuns para incorporar ao manual</h2><p><strong>Tag Poção:</strong> '''+e(rules['definicao_tag'])+'''</p><ol>'''+''.join('<li>'+e(rule)+'</li>' for rule in rules['regras'])+'''</ol><p>As definições comuns ficam no manual; cada carta apresenta seus efeitos próprios.</p></section>
<section id="correcoes"><h2>Últimas correções consolidadas</h2><div class="grid">'''+''.join(card(c) for c in updated)+'''</div></section><footer><h2>Fontes consultadas</h2><ul>'''+''.join(f'<li><a href="{e(s["url"])}">{e(s["titulo"])}</a></li>' for s in comparison['fontes'])+'''</ul><p>Textos de efeitos nas cartas são adaptações próprias. Nenhum PDF ou arte foi gerado nesta revisão.</p></footer></main></html>'''
output=ROOT.parent/'outputs/expansao_pocoes_2026-10-27/Comparacao_e_Novas_Pocoes.html'
output.parent.mkdir(parents=True,exist_ok=True)
output.write_text(page,encoding='utf-8')
print(json.dumps({'relatorio':str(output),'novas_pocoes':len(new),'total_catalogo':len(catalog)},ensure_ascii=False))
