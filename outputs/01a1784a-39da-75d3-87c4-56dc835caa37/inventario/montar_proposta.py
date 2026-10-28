"""Proposta de inventário, separada das regras canônicas e dos PDFs de cartas."""
import json,html,hashlib,math,sys
from pathlib import Path
from collections import Counter
sys.stdout.reconfigure(encoding='utf-8')
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[2]
catalog_path=ROOT/'producao_cartas/dados/catalogo_cartas.json'
cards=json.loads(catalog_path.read_text(encoding='utf-8'))['cartas']
CAP={'armadura':1,'costas':1,'cabeca':1,'pes':1,'acessorios':2,'amuletos':1,'armamentos':4,'consumiveis':6,'mochila':6}
labels={'armadura':'Armadura','costas':'Costas','cabeca':'Cabeça','pes':'Pés','acessorios':'Acessórios','amuletos':'Amuletos ou colares entre os acessórios','armamentos':'Armamentos e repertórios','consumiveis':'Consumíveis especiais','mochila':'Mochila'}
accessories={89,92,99,101,103,105,106,107,109,110,112,113,115}
foci={91,93,*range(116,127)}
utility_cost={81:1,82:1,83:1,84:2,85:2,86:1,87:2,88:1,90:1,95:1,96:2,97:1,98:1}
special_clothing={94:('costas',2),100:('pes',2),102:('costas',1),104:('cabeca',1),108:('pes',2),111:('cabeca',1),114:('pes',2)}
bulky_ranged={30,31,32,33,36,37,38,39,42,43,44,45}
bundle_throw={28,34}
rows=[]
for c in cards:
 num=int(c['id'][3:]);cat=c['categoria'];tag=c['tags'];slots={};bundle=1;reserve=1;note='';kind=''
 if cat.startswith('ARMA CORPO A CORPO'):
  kind='Armamento';cost=2 if 'Tamanho Grande' in tag else 1;slots={'armamentos':cost};reserve=0
  note='Precisa estar empunhada para fornecer benefícios e capacidade de Fadiga em combate.'
 elif cat.startswith('ARMA À DISTÂNCIA'):
  kind='Armamento';cost=2 if num in bulky_ranged else 1;slots={'armamentos':cost};reserve=0
  if num in bundle_throw:bundle=3;note='Até 3 exemplares iguais por estojo de 1 espaço de armamento. Rastrear cada peça arremessada.'
  else:note='Custo de transporte. As regras de mãos, alcance e recarga continuam independentes.'
 elif cat.startswith('ARMADURA'):
  kind='Vestido';slots={'armadura':1};reserve=2 if 'Leve' in tag else 4
  if num==52:slots['costas']=1;note='O Manto do Vento é ARMADURA no catálogo e também usa Costas. Não acumula outra armadura nem outra capa.'
 elif cat.startswith('ESCUDO'):
  kind='Armamento';slots={'armamentos':2 if 'Pesado' in tag else 1};reserve=0;note='Ocupa uma mão quando empunhado. Guardado não dá proteção nem recebe Fadiga de Conjuração.'
 elif num in foci:
  kind='Armamento';slots={'armamentos':2 if num in {117,118} else 1};reserve=0;note='Foco ocupa uma mão segundo as regras do projeto. Volume de 2 espaços não cria exigência de duas mãos.'
 elif num in {62,64}:
  kind='Suprimento de viagem';slots={'mochila':1};bundle=3;reserve=0;note='Até 3 unidades iguais por pacote. Tochas e rações não ocupam a bolsa de consumíveis especiais.'
 elif cat.startswith('CONSUMÍVEL') or cat=='RUNA CONSUMÍVEL':
  kind='Consumível especial';slots={'consumiveis':1};reserve=0;note='Cada dose, aplicação, bomba, runa, gazua ou uso da carta ocupa 1 carga. Limite 6 no total, inclusive se guardado em outra bolsa.'
 elif cat.startswith('GRIMÓRIO') or cat=='TEXTO SAGRADO':
  kind='Repertório';slots={'armamentos':1};reserve=0;note='Cada grimório ou texto sagrado usa 1 dos quatro espaços compartilhados com armas, escudos e focos, inclusive se for reserva. Só disponibiliza suas magias quando preparado.'
 elif cat=='AMULETO':
  kind='Acessório';slots={'acessorios':1,'amuletos':1};reserve=1;note='Usa um dos dois acessórios. Máximo 1 amuleto, independentemente de qual divindade.'
 elif num in accessories:
  kind='Acessório';slots={'acessorios':1};reserve=1
  if num==113:slots['amuletos']=1;note='O colar usa um dos dois acessórios e compete com amuletos pelo único lugar de pescoço.'
  elif num==92:note='É um acessório de arma: continua ocupando 1 dos dois acessórios quando instalada no arco.'
  elif num==99:note='Manopla usa acessório; não cria mão adicional nem altera a empunhadura das armas.'
  elif num==89:note='Mantém a habilidade de virar a arma. Não aumenta os quatro espaços de armamento.'
  elif num==101:note='Apesar do nome Pergaminho, a carta é permanente: usa acessório, não consumível nem repertório.'
  else:note='Acessório equipado; não fornece benefícios se estiver de reserva na mochila.'
 elif num in special_clothing:
  group,reserve=special_clothing[num];kind='Vestido';slots={group:1}
  if num==94:note='O Paraquedas Élfico compete por Costas com capas e mantos. Dobrado, pode ser reserva de 2 espaços na mochila.'
 elif num in utility_cost:
  kind='Ferramenta';slots={'mochila':utility_cost[num]};reserve=0;note='Retire para usar. Não concede bônus passivo de combate nem capacidade de Fadiga enquanto guardado.'
 else:raise ValueError((c['id'],c['nome'],'Item sem classificação'))
 rows.append({'id':c['id'],'nome':c['nome'],'categoria_original':cat,'tipo_inventario':kind,'ocupacao_em_uso':slots,'unidades_por_pacote':bundle,'reserva_na_mochila':reserve,'observacao':note,'campos':c['campos'],'tags_originais':tag})

rules=[
 ('Capacidade básica','Cada personagem tem 1 Armadura, 1 Costas, 1 Cabeça, 1 Pés, 2 Acessórios, 4 espaços compartilhados de Armamentos e Repertórios, 6 cargas de Consumíveis Especiais e 6 espaços de Mochila. Um dos dois acessórios pode ser um amuleto ou colar; não há um terceiro espaço de amuleto. O Colar Vinculador também usa esse limite de pescoço.'),
 ('Armamentos','Armas pequenas ou médias, escudo leve e focos compactos ocupam 1 espaço. Armas com Tamanho Grande, arcos, bestas, lanças de arremesso, escudo pesado e cajados longos ocupam 2. Até 3 shurikens ou 3 adagas balanceadas iguais formam um estojo de 1 espaço. Cada grimório ou texto sagrado ocupa 1 espaço. Armas, escudos, focos e livros de reserva também contam nos quatro espaços: escondê-los na mochila não aumenta o limite.'),
 ('Mãos são outra coisa','Espaço de transporte não é quantidade de mãos. O personagem tem suas duas mãos normais e respeita as exigências de empunhadura existentes. Tamanho Grande não passa automaticamente a exigir duas mãos. Armas e focos guardados não funcionam como itens empunhados.'),
 ('Consumíveis especiais','Cada dose, aplicação, runa, bomba, pergaminho consumível, flecha especial, gazua ou uso de Pedra de Amolar ocupa 1 carga. São 6 cargas ao todo, não 6 tipos. Seis curas preenchem a bolsa inteira. Não é permitido carregar mais doses próprias escondidas na mochila ou em outra bolsa.'),
 ('Suprimentos comuns','Tochas e Rações de Viagem ficam na mochila: até 3 unidades iguais ocupam 1 espaço. Um pacote parcialmente usado continua ocupando 1 espaço até esvaziar. Uma aljava ou estojo de munição comum ocupa 1 espaço de mochila; esta regra não cria contagem de munição onde o sistema não a faz. Flechas especiais continuam nas seis cargas de consumíveis.'),
 ('Mochila','Uma ferramenta ou item comum pequeno ocupa 1 espaço; um kit ou objeto volumoso, 2. Kit de Reparos, Kit de Acampamento, Equipamento de Pesca e Vara de 3 Metros usam 2. Corda, lanterna, ferramentas de ladrão, pederneira e os demais utensílios listados usam 1. Um kit contém seus componentes usuais e não serve para esconder itens sem relação com sua função.'),
 ('Reservas de vestuário','Apenas uma armadura pode estar vestida. Uma armadura leve reserva ocupa 2 espaços de mochila; média ou pesada, 4. Capa, elmo, máscara ou acessório reserva ocupa 1; par de botas, grevas ou paraquedas reserva ocupa 2. Guardar não permite usar o efeito de uma segunda peça. Armamentos, livros de repertório e consumíveis continuam respeitando seus limites próprios.'),
 ('Repertório preparado','Cada grimório ou texto sagrado ocupa 1 dos quatro espaços compartilhados com armas, escudos e focos. Não existem espaços extras nem um limite separado de dois repertórios. Antes da cena, durante uma pausa segura de pelo menos 1 minuto, escolha quais livros carregados estão preparados: são eles que disponibilizam suas magias, respeitando os requisitos existentes. Livros de reserva também contam nos mesmos quatro espaços, mesmo guardados na mochila. Escrituras de Maftoné continuam sendo FOCO SAGRADO no catálogo e usam seu espaço como foco, sem contagem dupla.'),
 ('Somente o equipamento ativo funciona','Proteções e acessórios só concedem seus efeitos quando vestidos nos espaços corretos. Armas, escudos e focos só os concedem quando empunhados. Livros de repertório só concedem as magias quando preparados. Ferramentas funcionam quando retiradas e usadas. Durante combate, equipamento de reserva não recebe Fadiga de Conjuração, não concede seus bônus e não recupera Fadiga passivamente.'),
 ('Trocas e Fadiga','Guardar, largar, trocar ou reequipar não remove fichas, não repara vida e não renova um uso limitado. Fora de combate, a recuperação normal de Fadiga continua valendo. Conserve as fichas nas cartas de reserva. Cópias de um mesmo acessório não acumulam bônus passivos.'),
 ('Acesso em combate','A bolsa especial fica acessível. Sacar sua dose faz parte do uso, sem cobrar uma segunda ação só por pegar o frasco; pague a ação da carta e tenha mão livre quando for necessário manipular o item. Retirar uma ferramenta da mochila custa 1 ação de Movimento, além da ação necessária para utilizá-la. Trocar armamento pequeno ou médio custa 1 Movimento; trocas que envolvem Tamanho Grande conservam o custo de duas ações da regra existente. Largar item continua ação livre.'),
 ('Troca de vestuário e repertório','Vestir ou ativar outra armadura, peça de roupa, acessório ou repertório de reserva exige uma pausa segura de pelo menos 1 minuto; não se faz durante o combate. É permitido retirar uma peça em combate para encerrar seu efeito, mas isso não permite ativar sua substituta imediatamente. Uma carta que diga expressamente que permite uma troca é uma exceção.'),
 ('Efeitos que já começaram','Poção consumida sai do inventário. Se sua carta fica na mesa para acompanhar duração ou a vida de Vigor Lunar, ela é só um marcador do efeito e não outra dose carregada. Efeitos já aplicados continuam pelo tempo da própria regra; retirar a fonte interrompe benefícios que dependam de vestir, empunhar ou manter o item ativo.'),
 ('Sem excesso e sem bolsas infinitas','Se não houver espaço, deixe, distribua ou transporte por animal ou veículo. Uma segunda mochila, saco ou bolso não aumenta a capacidade básica. O bolso secreto do Couro do Batedor ajuda a ocultar, mas não cria espaço. Peças de tamanho incompatível com um corpo, como barris e grandes baús, precisam de transporte separado. Agrupe moedas e pequenas joias em uma bolsa de tesouro de 1 espaço, sem registrar peça por peça para volume; quando a bolsa estiver cheia, o mestre avisa antes de acrescentar mais.'),
 ('Habilidades não são carga','Cartas de raça, classe, herói, background e habilidades representam o personagem e não ocupam inventário. Equipamentos continuam ocupando seus espaços mesmo que sua carta esteja virada ou temporariamente sem vida.'),
]

def classify_set(name,entries,extra=None):
 totals=Counter();descs=[]
 for id,quantity,state in entries:
  row=next(r for r in rows if r['id']==id)
  if state=='reserva':
   if row['reserva_na_mochila']>0:totals['mochila']+=row['reserva_na_mochila']*quantity
   else:
    for g,k in row['ocupacao_em_uso'].items():totals[g]+=k*math.ceil(quantity/row['unidades_por_pacote'])
  else:
   for g,k in row['ocupacao_em_uso'].items():totals[g]+=k*math.ceil(quantity/row['unidades_por_pacote'])
  descs.append(f'{quantity} × {row["nome"]}'+(' (reserva)' if state=='reserva' else ''))
 for g,q in (extra or {}).items():totals[g]+=q
 return {'nome':name,'itens':descs,'ocupacao':dict(totals),'excesso':{g:q-CAP[g] for g,q in totals.items() if q>CAP[g]}}
examples=[
 classify_set('Guerreiro de arma e escudo',[('EQ-007',1,'uso'),('EQ-056',1,'uso'),('EQ-001',1,'uso'),('EQ-047',1,'uso'),('EQ-061',3,'uso'),('EQ-063',1,'uso'),('EQ-065',1,'uso'),('EQ-127',1,'uso'),('EQ-085',1,'uso'),('EQ-081',1,'uso'),('EQ-083',1,'uso'),('EQ-062',3,'uso'),('EQ-064',3,'uso')]),
 classify_set('Arqueiro com alternativa corpo a corpo',[('EQ-032',1,'uso'),('EQ-004',1,'uso'),('EQ-001',1,'uso'),('EQ-046',1,'uso'),('EQ-102',1,'uso'),('EQ-100',1,'uso'),('EQ-092',1,'uso'),('EQ-103',1,'uso'),('EQ-061',2,'uso'),('EQ-159',1,'uso'),('EQ-169',1,'uso'),('EQ-079',2,'uso'),('EQ-085',1,'uso'),('EQ-081',1,'uso'),('EQ-083',1,'uso'),('EQ-064',3,'uso')],{'mochila':1}),
 classify_set('Mago com dois repertórios',[('EQ-117',1,'uso'),('EQ-139',1,'uso'),('EQ-142',1,'uso'),('EQ-068',3,'uso'),('EQ-061',2,'uso'),('EQ-131',1,'uso'),('EQ-085',1,'uso'),('EQ-083',1,'uso'),('EQ-064',3,'uso')]),
 classify_set('Corrente e proteção',[('EQ-156',1,'uso'),('EQ-055',1,'uso'),('EQ-001',1,'uso')]),
 classify_set('Excesso de armamentos',[('EQ-009',1,'uso'),('EQ-033',1,'uso'),('EQ-001',1,'uso')]),
 classify_set('Excesso de poções',[('EQ-061',4,'uso'),('EQ-068',3,'uso')]),
 classify_set('Duas armaduras vestidas',[('EQ-047',1,'uso'),('EQ-052',1,'uso')]),
 classify_set('Amuleto e outro acessório',[('EQ-137',1,'uso'),('EQ-103',1,'uso')]),
 classify_set('Dois amuletos',[('EQ-137',1,'uso'),('EQ-138',1,'uso')]),
 classify_set('Paraquedas e capa',[('EQ-094',1,'uso'),('EQ-102',1,'uso')]),
 classify_set('Armadura pesada de reserva ocupa a mochila',[('EQ-048',1,'reserva'),('EQ-085',1,'uso'),('EQ-081',1,'uso')]),
 classify_set('Amuleto e Colar Vinculador',[('EQ-137',1,'uso'),('EQ-113',1,'uso')]),
 classify_set('Repertório de reserva também conta',[('EQ-117',1,'uso'),('EQ-139',1,'uso'),('EQ-142',1,'uso'),('EQ-140',1,'reserva')]),
 classify_set('Foco compacto, adaga e dois repertórios',[('EQ-116',1,'uso'),('EQ-001',1,'uso'),('EQ-139',1,'uso'),('EQ-142',1,'uso')]),
 classify_set('Quatro repertórios sem arma nem foco',[('EQ-139',1,'uso'),('EQ-140',1,'uso'),('EQ-142',1,'uso'),('EQ-144',1,'uso')]),
]
assert all(not examples[i]['excesso'] for i in [0,1,2,3,7,13,14])
assert all(examples[i]['excesso'] for i in [4,5,6,8,9,10,11,12])
assert 'repertorios' not in CAP
assert all(r['ocupacao_em_uso']=={'armamentos':1} and r['reserva_na_mochila']==0 for r in rows if r['tipo_inventario']=='Repertório')
assert len(rows)==170 and len({r['id'] for r in rows})==170
obj={'titulo':'Inventário por espaços — proposta v01','data':'2026-10-27','status':'Proposta para discussão e teste; não incorporada ao catálogo, manual ou PDFs','capacidades':CAP,'regras':[{'titulo':t,'texto':v} for t,v in rules],'itens':rows,'exemplos':examples,'catalogo_sha256':hashlib.sha256(catalog_path.read_bytes()).hexdigest(),'fontes_projeto':['SISTEMA_21_Estado_do_Projeto.md, seções 4, 7, 8 e 9','producao_cartas/dados/catalogo_cartas.json, coleção v06','producao_cartas/dados/regras_pocoes_para_manual.json']}
(OUT/'Inventario_por_Espacos_v01.json').write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
E=lambda v:html.escape(str(v))
cap_rows=''.join(f'<tr><td>{E(labels[k])}</td><td>{v}</td><td>{E(note)}</td></tr>' for k,v,note in [('armadura',1,'Uma proteção principal vestida.'),('costas',1,'Capa, manto ou paraquedas.'),('cabeca',1,'Elmo ou máscara.'),('pes',1,'Um par de botas ou grevas.'),('acessorios',2,'No máximo um amuleto ou colar entre os dois; cinto, manopla e talismãs também competem aqui.'),('armamentos',4,'Espaços compartilhados para armas, escudos, focos, grimórios e textos sagrados, incluindo reservas.'),('consumiveis',6,'Doses ou usos, não seis tipos diferentes.'),('mochila',6,'Ferramentas, suprimentos e reservas de vestuário.')])
rules_html=''.join(f'<article><h3>{n+1}. {E(t)}</h3><p>{E(v)}</p></article>' for n,(t,v) in enumerate(rules))
def occupation(r):return ' + '.join(f'{v} {labels[k]}' for k,v in r['ocupacao_em_uso'].items())
itemrows=''.join(f'<tr><td>{r["id"]}</td><td>{E(r["nome"])}</td><td>{E(occupation(r))}'+(f'<br><small>até {r["unidades_por_pacote"]} unidades iguais por pacote</small>' if r['unidades_por_pacote']>1 else '')+f'</td><td>{str(r["reserva_na_mochila"])+" Mochila" if r["reserva_na_mochila"] else "Mantém seu limite próprio"}</td><td>{E(r["observacao"])}</td></tr>' for r in rows)
example_html=''.join(f'<article class="example"><h3>{E(x["nome"])} — {"excede o limite" if x["excesso"] else "cabe"}</h3><p>{E("; ".join(x["itens"]))}</p><p><strong>Ocupação:</strong> '+E('; '.join(f'{labels[g]} {q}/{CAP[g]}' for g,q in x['ocupacao'].items()))+'</p>'+(('<p class="bad">Excesso: '+E('; '.join(f'{q} em {labels[g]}' for g,q in x['excesso'].items()))+'</p>') if x['excesso'] else '')+('</article>') for x in examples)
doc=f'''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sistema 21 — inventário por espaços</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#f1ede4;color:#29261f;font:16px/1.65 Arial,sans-serif}}main{{max-width:1120px;margin:24px auto;background:#fffdf8;padding:44px 48px}}h1,h2,h3{{font-family:Georgia,serif;color:#463722}}h1{{font-size:40px;line-height:1.2;margin:12px 0 22px}}h2{{font-size:29px;margin:38px 0 20px}}h3{{font-size:20px}}.meta{{font-size:12px;color:#77654a;letter-spacing:.06em}}.lead{{font-size:20px;max-width:850px}}p{{margin:12px 0 20px}}table{{border-collapse:collapse;width:100%;font-size:14px;line-height:1.5}}th,td{{text-align:left;padding:12px;border-bottom:1px solid #ddd2bd;vertical-align:top}}th{{background:#e9e0ce;color:#49391e}}small{{font-size:12px;color:#756748}}.scroll{{overflow-x:auto}}.rule{{border-left:4px solid #a3823e;background:#f3ecde;padding:15px 22px;margin:26px 0}}.example{{border-bottom:1px solid #dacfbb;padding-bottom:12px}}.bad{{color:#8a3f2d;font-weight:bold}}article p{{max-width:980px}}nav{{display:flex;gap:20px;flex-wrap:wrap;border-block:1px solid #d9ccb3;padding:14px 0}}a{{color:#775621}}.sheet{{display:grid;grid-template-columns:1fr 1fr;gap:25px;margin:28px 0}}.line{{border-bottom:1px solid #cbbda2;height:38px}}.label{{font-size:13px;color:#66563c}}.boxes{{display:flex;gap:10px;flex-wrap:wrap}}.box{{width:37px;height:37px;border:1px solid #a7997c;background:#fffdf8;display:grid;place-items:center;color:#8d8065;font-size:12px}}@media(max-width:720px){{main{{margin:0;padding:28px 20px}}h1{{font-size:31px}}.sheet{{grid-template-columns:1fr}}}}@media print{{body{{background:white}}main{{max-width:none;padding:0;margin:0}}nav{{display:none}}table{{font-size:10pt}}tr,article,.sheet{{break-inside:avoid}}.scroll{{overflow:visible}}h1{{font-size:28pt}}h2{{font-size:21pt}}}}
</style><main><div class="meta">SISTEMA 21 · MASMORRAS · PROPOSTA v01 · 27/10/2026</div><h1>Inventário por espaços</h1><p class="lead">Poucos limites fixos por tipo de equipamento e seis espaços de mochila. Sem quilos, litros ou soma de carga por atributo.</p><div class="rule"><strong>Regra central:</strong> carregar não é equipar. A reserva ocupa espaço, mas não concede proteção, bônus ou capacidade de Fadiga em combate. As categorias abaixo são propostas para testar na mesa, preservando o texto dos 170 itens.</div><nav><a href="#resumo">Capacidades</a><a href="#regras">Regras completas</a><a href="#exemplos">Exemplos conferidos</a><a href="#classificacao">Os 170 itens</a><a href="#ficha">Ficha de controle</a></nav>
<h2 id="resumo">Capacidade de um personagem</h2><div class="scroll"><table><thead><tr><th>Espaço</th><th>Limite</th><th>O que entra</th></tr></thead><tbody>{cap_rows}</tbody></table></div><p><strong>Escolhas de armamento:</strong> espada, escudo leve e arco ocupam 1 + 1 + 2 = 4. Maça, escudo pesado e faca ocupam 1 + 2 + 1 = 4. Montante e besta ocupam 2 + 2 = 4; acrescentar uma faca excede o limite. Esses números descrevem transporte, sem mudar a regra de mãos de cada item.</p>
<h2 id="regras">Regras para o manual</h2>{rules_html}<p><strong>Exceções de vestuário já identificadas:</strong> Manto do Vento ocupa Armadura e Costas. Paraquedas Élfico e Manto Camuflado competem por Costas. Elmo de Touro e Máscara do Impostor competem por Cabeça. Botas de Lince, Botas Seccundas e Grevas do Vazio competem por Pés. Anel, cinto, manopla, bandoleira, bainha e talismãs disputam os dois acessórios. Não foram criadas novas definições de peso para essas cartas.</p>
<h2 id="exemplos">Exemplos conferidos</h2><p>“Em uso” na ocupação significa equipado ou reservado na categoria adequada. No caso de armas e focos, somente os efetivamente empunhados funcionam em combate. O arqueiro também reserva um espaço de mochila para a aljava, já incluído na ocupação mostrada.</p>{example_html}
<h2 id="classificacao">Classificação dos 170 itens</h2><p>“Reserva na mochila” vale para peças de vestuário e acessórios que você leva sem equipar. Armamentos, grimórios, textos sagrados e consumíveis especiais continuam usando seus próprios limites mesmo guardados: não ganham capacidade extra por estar em outra bolsa.</p><div class="scroll"><table><thead><tr><th>ID</th><th>Item</th><th>Ocupação</th><th>Se for reserva</th><th>Observação</th></tr></thead><tbody>{itemrows}</tbody></table></div>
<h2 id="ficha">Ficha simples de controle</h2><div class="sheet"><div><div class="label">ARMADURA</div><div class="line"></div><div class="label">COSTAS</div><div class="line"></div><div class="label">CABEÇA</div><div class="line"></div><div class="label">PÉS</div><div class="line"></div></div><div><div class="label">ACESSÓRIO 1 — no máximo um amuleto ou colar entre os dois</div><div class="line"></div><div class="label">ACESSÓRIO 2</div><div class="line"></div></div></div><div class="sheet"><div><p class="label">ARMAMENTOS E REPERTÓRIOS — 4 ESPAÇOS</p><div class="boxes">{''.join(f'<div class="box">{i}</div>' for i in range(1,5))}</div><p class="label">CONSUMÍVEIS ESPECIAIS — 6 CARGAS</p><div class="boxes">{''.join(f'<div class="box">{i}</div>' for i in range(1,7))}</div></div><div><p class="label">MOCHILA — 6 ESPAÇOS</p>{''.join('<div class="line"></div>' for _ in range(6))}</div></div><p>Marque dois espaços para cada armamento volumoso e um para cada grimório ou texto sagrado. Livros preparados e de reserva compartilham esse mesmo limite. Para cópias de consumíveis, uma carta e marcadores de quantidade podem representar as doses. Cartas mantidas apenas para acompanhar efeitos já consumidos ficam fora da contagem de carga.</p><p class="meta">Base consultada: estado do projeto, seções 4, 7, 8 e 9; catálogo v06; regras gerais das poções. Esta proposta não altera esses arquivos nem os PDFs.</p></main></html>'''
target=OUT/'Inventario_por_Espacos_v01.html';target.write_text(doc,encoding='utf-8')
qa={'itens_classificados':170,'categorias_170':dict(Counter(r['tipo_inventario'] for r in rows)),'exemplos_conferidos':len(examples),'casos_que_cabem':sum(not x['excesso'] for x in examples),'casos_com_excesso':sum(bool(x['excesso']) for x in examples),'sem_limite_alternativo_por_bolsa':True,'catalogo_preservado':hashlib.sha256(catalog_path.read_bytes()).hexdigest()==obj['catalogo_sha256'],'status':'Proposta para revisão; sem alteração do manual ou dos PDFs'}
(OUT/'qa_inventario_v01.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(qa,ensure_ascii=False))
