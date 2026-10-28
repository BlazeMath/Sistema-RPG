import json, hashlib, csv, sys
from decimal import Decimal, ROUND_HALF_UP, ROUND_FLOOR
from pathlib import Path
sys.stdout.reconfigure(encoding='utf-8')
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[2]
catalog_path=ROOT/'producao_cartas/dados/catalogo_cartas.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))['cartas']
valuation=json.loads((OUT/'avaliacoes_autorais_v01.json').read_text(encoding='utf-8'))['itens']
research=json.loads((OUT/'fontes_pesquisa.json').read_text(encoding='utf-8'))
markets=[
 {'codigo':'V','nome':'Vila','min':.8,'max':1.25,'revenda':.4,'acesso':'Comércio de abastecimento ou artesão local. Estoque comum, sem garantia de quantidade.'},
 {'codigo':'C','nome':'Cidade','min':.8,'max':1.3,'revenda':.4,'acesso':'Oficina, feira ou loja urbana; pode exigir encomenda simples.'},
 {'codigo':'E','nome':'Especialista','min':.7,'max':1.4,'revenda':.35,'acesso':'Alquimista, mestre de ofício ou círculo de iniciados. Nem todo povoado tem um.'},
 {'codigo':'O','nome':'Encomenda','min':.65,'max':1.5,'revenda':.3,'acesso':'Encomenda, instituição ou oficina excepcional; aquisição requer contato e prazo.'},
 {'codigo':'R','nome':'Relíquia','min':.6,'max':1.6,'revenda':.25,'acesso':'Referência de avaliação para negociação entre especialistas; não pressupõe estoque ou comprador.'},
]
marketmap={m['codigo']:m for m in markets}
assert len(catalog)==len(valuation)==170
assert {c['id'] for c in catalog}=={v['id'] for v in valuation}
vals={v['id']:v for v in valuation}
items=[]
for c in catalog:
 v=vals[c['id']];m=marketmap[v['mercado']]
 base=round(v['suporte_prata']*10);price=round(v['preco_prata']*10)
 assert price>=base>0,c['id']
 rarity=c['categoria'].rsplit('·',1)[-1].strip() if '·' in c['categoria'] else 'Não informada'
 rounded=lambda factor,mode:float((Decimal(price)*Decimal(str(factor))).quantize(Decimal('1'),rounding=mode))/10
 item=dict(v,id=c['id'],nome=c['nome'],categoria=c['categoria'].split('·')[0].strip(),raridade=rarity,habilidade=c['habilidade'],tags=c['tags'],campos=c['campos'],imagem=c['imagem'],suporte_cobre=base,premio_cobre=price-base,preco_cobre=price,preco_ouro=price/1000,faixa_baixa_prata=rounded(m['min'],ROUND_HALF_UP),faixa_alta_prata=rounded(m['max'],ROUND_HALF_UP),revenda_prata=rounded(m['revenda'],ROUND_FLOOR),dias_salario_bruto=price/20,mercado_nome=m['nome'],faixa_min=m['min'],faixa_max=m['max'],fator_revenda=m['revenda'])
 items.append(item)
params={'cobres_por_prata':10,'pratas_por_ouro':100,'diaria_trabalhador_cobre':20,'diaria_artesao_cobre':60,'dias_remunerados_ano':250,'multiplicador_mercado':1,'grupo':4,'contrato_prata':120,'saque_prata':24,'pousada_por_heroi_prata':5,'racoes':4,'curas':2,'manas':1,'tochas':4}
living=[['Pão simples',.1,'1 unidade','Referência de abastecimento, sem efeito de carta'],['Refeição simples',.3,'1 refeição','Comida comum, sem bônus na mão inicial'],['Alimentação frugal',.8,'pessoa/dia','Consumo civil de referência'],['Pouso em celeiro',.2,'pessoa/noite','Proteção básica, sem serviço de estalagem'],['Cama em hospedaria',1.5,'pessoa/noite','Só alojamento comum'],['Descanso atendido',5,'pessoa/estadia','Pacote de estalagem, alimentação e cuidados; não cria exigência de dormir em estalagem'],['Diária de trabalhador',2,'dia remunerado','Remuneração bruta, não poupança'],['Diária de artesão',6,'dia remunerado','Ofício estabelecido; não receita total de oficina'],['Diária de mercenário',8,'dia de contrato','Equipamento e risco podem ser negociados à parte'],['Diária de especialista',12,'dia de serviço','Escriba, perito ou curador; preço de referência'],['Diária de mestre raro',24,'dia de serviço','Ofício excepcional; não inclui reagentes ou fabricação de relíquias']]
model={'titulo':'Sistema 21 — estudo econômico e preços propostos','data':'2026-10-27','versao':'v01','status':'Proposta para discussão e playtest; não altera PDFs, catálogo nem protótipo','catalogo_sha256':hashlib.sha256(catalog_path.read_bytes()).hexdigest(),'parametros':params,'mercados':markets,'vida_civil':living,'fontes':research,'itens':items}
(OUT/'modelo_economico_v01.json').write_text(json.dumps(model,ensure_ascii=False,indent=2),encoding='utf-8')
with (OUT/'Tabela_Precos_170_Itens_v01.csv').open('w',encoding='utf-8-sig',newline='') as f:
 w=csv.writer(f,delimiter=';');w.writerow(['ID','Item','Categoria','Raridade da carta','Unidade','Compra (prata)','Compra (ouro)','Faixa baixa (prata)','Faixa alta (prata)','Revenda referência (prata)','Diárias brutas','Acesso','Justificativa','Ressalva'])
 for i in items:w.writerow([i[k] for k in ['id','nome','categoria','raridade','unidade','preco_prata','preco_ouro','faixa_baixa_prata','faixa_alta_prata','revenda_prata','dias_salario_bruto','mercado_nome','justificativa','ressalva']])
unrated=sum(i['raridade']=='Não informada' for i in items)
print(json.dumps({'itens':len(items),'raridade_nao_informada':unrated,'menor_preco_prata':min(i['preco_prata'] for i in items),'maior_preco_prata':max(i['preco_prata'] for i in items),'ouro_em_diarias_brutas':50},ensure_ascii=False))
