"""Aplica a revisão autorizada; preserva integralmente a entrada da Fênix."""
from pathlib import Path
import copy, hashlib, json

ROOT=Path(__file__).resolve().parents[2]
DATA=ROOT/'classes/dados/bruxo'
def read(name): return json.loads((DATA/name).read_text(encoding='utf-8'))
def write(name,data): (DATA/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

pacts=copy.deepcopy(read('novos_pactos_v02.json'))
skills=copy.deepcopy(read('habilidades_gerais_v02.json'))
rules=copy.deepcopy(read('regras_propostas_lote_v02.json'))
original_fenix=copy.deepcopy(pacts['patronos'][0])
p={x['id']:x for x in pacts['patronos']}
g={x['id']:x for x in skills['cartas']}
def spell(ident,side,text): p[ident]['habilidade']['lados'][side]['texto']=text
def face(ident,side,text): g[ident]['lados'][side]['texto']=text

p['BR-P01']['heroi']['desencadeada']='Uma vez no seu turno, depois de resolver uma magia concedida por este pacto em cujo custo você exilou cartas do baralho, retire 1 de Fadiga da carta em que a Fadiga daquela conjuração foi efetivamente paga. Se foi distribuída, escolha uma das cartas que a receberam. Pague normalmente antes de conjurar; a recuperação posterior não reduz esse custo.'
p['BR-P01']['menor']='Uma vez por cena, 1 Pacto da reserva menor: depois de estourar e comprar a carta final, pague este custo, exile-a e compre outra para determinar o resultado. Apenas uma substituição por teste. A cobrança menor aplica-se somente ao teste em que você usou este favor.'
p['BR-P01']['cobranca_menor']='Somente no teste em que usar o favor menor, a carta final substituta vai ao exílio ao terminar o teste. Recusar essa entrega suspende o vínculo menor; repare exilando 2 cartas do topo do baralho, sem gerar Pacto. Os demais estouros não geram esta cobrança menor.'

p['BR-P02']['heroi']['ativada']='X Pactos, Reação: quando um ataque inimigo fosse causar dano ao protegido em alcance curto, depois das resistências e antes da distribuição entre armadura, escudo e baralho, pague o custo e reduza esse dano em 3X, até o mínimo de zero. Uma ativação por ataque.'
p['BR-P02']['pacto']['escolha']+=' O protegido inconsciente continua sob sua guarda. Se morrer ou sair definitivamente da cena, escolha outro aliado até o fim de seu próximo turno, pagando a ação e descartando a reserva como numa troca normal. Até essa escolha, não use efeitos que exijam protegido nem ganhe Pacto por protegê-lo. Se não houver outro aliado na cena, a escolha fica pendente até haver um; não há cobrança de distância contra um protegido ausente.'
p['BR-P02']['pacto']['cobranca']+=' Uma impossibilidade que você criou voluntariamente para abandonar o protegido não concede essa exceção. Se a substituição necessária for possível e você a recusar no prazo, suspenda o pacto; repare escolhendo o novo protegido, ficando adjacente e renovando o juramento com a ação Padrão da reparação.'
p['BR-P02']['habilidade']['lados'][1]['texto']+=' No seu primeiro turno da cena, considere os ataques desde o começo da cena.'

p['BR-P03']['heroi']['ativada']='1 Pacto, Reação: quando um inimigo em alcance curto colocar a carta Fechada num teste de que você participa, pague o custo e revele-a a todos até a resolução desse teste. Não exige Marcação; também permite aos aliados conhecerem a carta.'
p['BR-P03']['heroi']['desencadeada']='Uma vez por rodada, depois de vencer um ataque ou defesa contra um inimigo cuja carta Fechada você tenha conhecido naquele teste, por Marcação, por um efeito de olhar ou por revelação pública, ganhe 1 ficha de Foco. Apenas saber que existe uma carta Fechada não conta.'
p['BR-P03']['teste']='Testar a frequência do ganho por estouro inimigo. Olhar informa apenas quem olha; revelar torna a carta pública. Marcação permite ao Bruxo conhecer a Fechada e satisfaz sua desencadeada; a ativada também funciona sem marcar. Veredito continua permitindo perder ou estourar.'

spell('BR-P04',1,'1 de Fadiga e 1 Pacto, Ação de Movimento: troque de lugar com um aliado que você possa ver em alcance curto. Para escolher um inimigo em vez de aliado, o custo total é 1 de Fadiga e 2 Pactos: faça um teste contestado de Espírito contra Espírito dele; se vencer, troquem de lugar. Ambos precisam caber nos destinos. A troca ignora impedimento e não provoca ataques de oportunidade; não atravessa paredes que bloqueiem a linha de visão.')
p['BR-P04']['heroi']['ativada']='1 Pacto, Reação: quando um aliado em alcance curto for escolhido como alvo de um ataque, antes de começar os testes desse ataque, pague o custo; ele pode mover-se 1 quadrado ignorando impedimento e sem provocar ataques de oportunidade. Respeite obstáculos e estados que impeçam movimento. Se continuar válido, o ataque mantém esse alvo. Se deixar de ser válido, o atacante pode escolher outro alvo válido para o mesmo ataque, conservando modo, custos e aprimoramentos já escolhidos; se não houver, o ataque termina sem efeito e a ação e os custos já pagos permanecem gastos. Uma ativação por ataque.'

spell('BR-P05',1,'2 de Fadiga e 1 Pacto, Ação Padrão: escolha um inimigo em alcance curto que tenha Imobilizar colocado por você e não tenha Atordoamento deste efeito colocado por você. Faça um teste contestado de Espírito contra Espírito dele. Se vencer, mantenha Imobilizar e coloque 1 ficha de Atordoamento na mesma carta. Esse Atordoamento é descartado no fim do próximo turno do alvo, se não tiver sido removido antes. Você só pode manter 1 Atordoamento desta magia por alvo; novas utilizações não acumulam nem renovam sua duração enquanto a ficha estiver presente.')
p['BR-P05']['teste']='Peso da Sentença mantém a prisão e acrescenta um único Atordoamento temporário por alvo. Testar contra chefes e criaturas com uma só carta; preservar opções reais de remover estados. A regra geral de qual ação Atordoamento retira deve constar do livro, sem criar uma definição diferente só para este pacto.'

p['BR-P06']['heroi']['ativada']='X Pactos: antes de comprar as cartas de um ataque mágico concedido por este pacto contra alvo com Atormentado, ou antes do teste contestado de Devorar o Esforço contra alvo com Atormentado, pague o custo para aumentar em 2X o dano dessa magia se ela causar dano. Depois de aplicar as resistências, se o alvo sofrer dano, você pode curar X seguindo o exílio normal da cura. Em Devorar, é necessário vencer e remover pelo menos 1 Fadiga para haver dano a aprimorar; seu dano básico continua 2 por ficha removida, sem acrescentar foco ou Espírito novamente. Uma ativação por conjuração.'
p['BR-P06']['pacto']['cobranca']='Quando remover Fadiga de um inimigo com uma magia deste pacto, até o fim de seu próximo turno somente a recuperação normal de fim de turno e a desencadeada deste patrono podem remover sua Fadiga voluntariamente. Isso inclui remoções de outras habilidades suas, de aliados e por virar cartas que tenham Fadiga. Você pode optar por recebê-las ou por virar, mas isso quebra o compromisso. Remoção imposta por um inimigo não é quebra voluntária. Transferir Fadiga sem apagar fichas não é removê-la.'
p['BR-P06']['pacto']['quebra']='Remover voluntariamente sua Fadiga por outra fonte no prazo suspende o pacto depois que essa remoção for resolvida.'
p['BR-P06']['cobranca_menor']='Depois de usar o favor menor, até o fim de seu próximo turno somente a recuperação normal e a recuperação concedida pelo próprio favor menor podem remover sua Fadiga voluntariamente. Outras remoções, inclusive virar cartas com Fadiga, suspendem o vínculo após a resolução; remoções impostas pelo inimigo não contam. Repare com uma ação Padrão e descarte de 2 cartas da mão.'

p['BR-P07']['habilidade']['lados'][1]['texto']+=' Uma utilização desta magia por ataque inimigo, salvo a única repetição expressamente autorizada por Intercessão do Patrono.'
p['BR-P07']['heroi']['ativada']+=' Pague os Pactos e a Reação no acerto, antes de terminar a conjuração; uma ficha de Reação que só será recebida depois dela ainda não está disponível.'
p['BR-P07']['heroi']['desencadeada']+=' A ficha só fica disponível ao terminar a resolução completa da magia e de seus efeitos adicionais; não paga a ativada durante o acerto dessa mesma magia.'
p['BR-P07']['cobranca_menor']+=' Você pode abrir mão da recuperação normal de 1 de Fadiga para conservar a última ficha exigida. Verifique essa conservação depois de resolver as recuperações do fim do turno.'

p['BR-P08']['pacto']['cobranca']='Uma vez por cena, depois de comprar a mão inicial e antes de usar benefícios deste pacto, escolha 1 carta dessa mão e exile-a como sonho entregue à patrona. Esse exílio obrigatório não gera Pacto. Entregar uma vez satisfaz a cobrança dessa cena; virar cartas ou usar outros benefícios não exige nova entrega.'
p['BR-P08']['cobranca_menor']='Uma vez por cena, depois da mão inicial e antes de usar o favor menor, exile 1 carta da mão como sonho entregue. Recusar suspende o vínculo; reparar exige uma ação Padrão e exilar 1 carta da mão. A reparação satisfaz a entrega pendente dessa cena. Virar a carta não apaga o pagamento nem cria nova cobrança; o exílio obrigatório não gera Pacto.'

p['BR-P09']['heroi']['desencadeada']='Uma vez no seu turno, se a habilidade inicial deste pacto estava abaixo do limite imediatamente antes de conjurar e atingiu exatamente o limite durante o pagamento ou as transferências daquela magia, depois de resolver a magia, se você não tiver Bloqueio, coloque 1 Bloqueio em sua carta de herói. A carta precisa continuar no limite nesse momento. Uma carta já cheia, transbordo ou transferência alheia a essa conjuração não dispara o efeito.'
p['BR-P09']['habilidade']['lados'][1]['texto']+=' A quantidade transferida não pode superar o menor entre 2, a Fadiga disponível na carta de origem e o espaço livre nesta carta depois de pagar a conjuração.'
p['BR-P09']['pacto']['cobranca']='Em qualquer turno, seu ou de outra criatura, se gastar fichas deste pacto, não pode ter se deslocado voluntariamente naquele turno nem se deslocar voluntariamente pelo restante dele. Deslocamento imposto por outra criatura não quebra o compromisso. Se escolher mover e gastar no mesmo turno, suspenda o pacto depois da ação que provocar a quebra. Um gasto em turno alheio não prolonga por si só essa obrigação até seu próximo turno.'
p['BR-P09']['teste']='Coração transfere Fadiga sem apagá-la, até o espaço livre após o pagamento. Atingir o limite durante a magia pode conceder Bloqueio uma vez no próprio turno; uma carta já cheia não repete o gatilho. Testar se a potência compensa permanecer na posição nos turnos de gasto. Virar cartas continua permitido, respeitando eventuais cobranças de outros vínculos.'

face('BR-G01',0,'Ao adquirir esta carta por 1 XP, associe um patrono secundário diferente do pleno. Pode adquiri-la novamente para outros patronos, usando uma carta e uma reserva separadas por vínculo. Cada pacto menor começa no nível 1 e progride independentemente até 5, quando o mestre reconhecer seu cumprimento. Suas tags, reserva e cobrança menor permanecem nos dois lados. No começo da cena, cada reserva menor recebe N Pactos, sendo N seu próprio nível. Neste lado, use apenas o favor menor; não recebe a inicial A/B, efeitos de herói, ganho por cumprimento nem por crítico. Virar não repete o ganho inicial nem permite trocar o patrono associado.')
face('BR-G01',1,'2 Pactos da reserva menor, Ação de Movimento: retire 1 de Fadiga da habilidade inicial de seu pacto pleno. Uma vez por turno. A reserva, as tags e a cobrança menor permanecem neste lado, mas o favor menor fica inativo. No nível 1, a reserva inicial de 1 não paga este custo sem outra fonte de Pacto. Virar não repete o ganho inicial nem altera o nível ou o patrono associado.')
g['BR-G02']['lados'][0]['texto']+=' Se o Abismo for seu pacto pleno regular, este custo de exílio pode gerar separadamente seu 1 Pacto por turno. O ganho de 2 desta habilidade não é cumprimento; o ganho separado do Abismo é, e continua sujeito ao limite dele.'
face('BR-G03',0,'1 de Fadiga e 1 Pacto: antes de conjurar uma magia concedida por esse pacto que afetaria dois ou mais inimigos, mantenha somente seu alvo principal, que já receberia dano direto da magia, e ignore todos os efeitos dela nos demais inimigos. Se causar dano direto ao principal, some novamente seu Espírito a esse dano. Não muda o alvo do teste, não dispensa defesa nem cria dano onde não havia. Os efeitos abandonados nos secundários podem ser somente fichas. Uma aplicação por conjuração.')
face('BR-G03',1,'2 de Fadiga e 1 Pacto: depois de sua magia desse pacto acertar e colocar fichas no alvo principal, pague este custo e faça um novo teste de ataque mágico contra outro inimigo adjacente a ele. Se acertar, coloque 1 ficha de um dos tipos que a magia colocou no primeiro alvo, mantendo duração, remoção e limites de quantidade daquela magia, inclusive limites por alvo e por conjurador. O ataque adicional não causa dano, não recebe aprimoramentos nem gera outra extensão. Uma extensão por conjuração. O pagamento é posterior ao acerto original e não modifica sua resolução.')
face('BR-G04',1,'1 de Fadiga: imediatamente depois de comprar as duas cartas iniciais de um ataque mágico concedido por seu pacto pleno, mas antes de verificar se estourou e antes das compras adicionais, pague o custo, coloque a carta Aberta no fundo do baralho e revele uma substituta. Recalcule o total inicial com ela e então verifique o estouro normalmente. Uma vez por teste; não reabre um estouro já resolvido.')
face('BR-G06',1,'1 de Fadiga e 1 Pacto: depois de resolver um ataque mágico estourado concedido por esse pacto e enviar suas cartas ao destino normal, pague o custo e devolva à mão 1 carta comum usada naquele teste que ainda esteja no seu descarte. Não refaz o ataque nem recupera carta exilada. Uma vez por teste. O pagamento ocorre neste gatilho posterior.')
g['BR-M02']['lados'][0]['texto']='1 Pacto: no fim do seu turno, depois de resolver ou renunciar à recuperação normal e receber os ganhos de Pacto devidos por essa escolha, pague o custo e retire 1 de Fadiga adicional da habilidade inicial daquele pacto. Uma vez por turno. Esta é uma recuperação adicional e não substitui a normal a que renunciou. Depois dela, verifique as cobranças de conservação de Fadiga e respeite as restrições de outros vínculos.'
g['BR-M04']['lados'][0]['texto']+=' Se o Abismo for seu pacto pleno regular, o custo de exílio também pode gerar separadamente o 1 Pacto do benefício dele, uma vez no seu turno. O ganho próprio desta habilidade não conta como cumprimento; o ganho separado do Abismo conta, sem repetir o próprio gatilho.'
face('BR-M06',0,'1 Pacto: depois de resolver a falha de um ataque mágico concedido por aquele pacto e enviar suas cartas ao destino normal, pague este custo e devolva ao fundo do baralho 1 carta comum usada nesse teste que ainda esteja no seu descarte. Uma vez por ataque; não recupera cartas exiladas. Pode combinar com outra recuperação usando cartas diferentes; a carta que já saiu do descarte não pode ser escolhida novamente.')
g['BR-X01']['lados'][1]['texto']+=' Funciona em qualquer virada para este lado, inclusive uma virada manual paga pela ação normal; não exige Manifestação Dupla anterior.'
g['BR-X02']['lados'][0]['texto']+=' Não se aplica a ativações do herói nem a custos de apenas 1 Pacto.'
g['BR-X03']['lados'][0]['texto']+=' Pague o custo de Intercessão depois da primeira falha resolvida. Se a face for uma magia de Reação, esta habilidade autoriza uma única repetição imediata na janela do gatilho original, mesmo sem novo ataque inimigo e sem gastar outra Reação; é exceção expressa ao limite de uma utilização daquela magia por ataque. As demais condições e alvos precisam continuar válidos e todos os recursos da nova conjuração são pagos novamente.'

for patron in pacts['patronos'][1:]:
 patron['rotulo_estado']='Revisão aplicada conforme autorização do autor; equilíbrio numérico em playtest.'
 for f in patron['habilidade']['lados']:
  f['conjuracao']=(patron['id']=='BR-P07' and f['lado']=='A')
  f['rapida']=(f['acao']=='Reação')
for c in skills['cartas']:
 c.pop('notas_de_revisao',None)

rules['convencoes_propostas']=[s for s in rules['convencoes_propostas'] if not any(t in s for t in ['Quando o texto suspender','Nos nove patronos propostos','Não foi alterada a cobrança','limite de Fadiga do herói','Reativar uma face','A cobrança menor vale'])]
rules['ajustes_aplicados']=[
 'Suspensão nos nove pactos além da Fênix: ficam inativos ganhos e gastos de Pacto, favor menor, ativada, desencadeada, crítico e aprimoramentos concedidos pelo vínculo. As tags e a associação permanecem, e as magias básicas continuam acessíveis para reparar. Aprimoramento é uma opção adicional da própria magia ou do patrono; o efeito básico obrigatório não é retirado. Habilidades gerais não podem alimentar a reserva suspensa ou restituir um benefício suspenso. A Fênix não recebe essa regra: sua consequência continua em aberto.',
 'Efeitos já resolvidos, fichas já colocadas e custos pagos não são desfeitos por suspensão, salvo texto expresso. Depois da reparação, o vínculo volta a funcionar sem refazer o ganho inicial da cena.',
 'Cartas dos nove heróis revisados têm limite 4. Pacto fica na carta do contrato e não ocupa capacidade de Fadiga. O limite da Fênix permanece como estava, sem nova definição.',
 'Magia Arcana classifica as habilidades iniciais; não concede por si só uma tag adicional à carta de herói. O Bruxo recebe Pacto e as tags expressamente concedidas por seus vínculos. Requisitos de itens continuam normais.',
 'Conjuração está expressa em Fagulha Cativa. As demais faces dos nove patronos não têm esse símbolo; pagam na própria carta, salvo outro efeito que autorize distribuição. A Fênix mantém sua definição anterior. Recuperações ligadas ao pagamento identificam a carta que efetivamente recebeu Fadiga.',
 'Magias identificadas como rápidas usam Reação no gatilho escrito. Dispensa de ação não elimina condições, salvo a autorização expressa de repetição de Intercessão. Uma vez por turno inclui turnos alheios; uma vez no seu turno é restrito ao próprio.',
 'Custos normalmente são pagos antes do teste. Quando uma habilidade é usada depois de acerto, falha, estouro, dano ou descarte, seus próprios recursos são pagos nessa janela posterior, antes do efeito adicional. Isso não reabre a resolução anterior.',
 'Olhar uma carta informa apenas quem a olha; revelar a torna pública. A desencadeada do Olho considera uma Fechada conhecida pelo Bruxo, inclusive por Marcação. Não exige revelá-la publicamente para receber Foco.',
 'No fim do turno: resolva ou renuncie à recuperação normal; resolva ganhos que dependam dessa escolha; depois as recuperações adicionais declaradas para essa janela; por último confira cobranças que exigem conservar Fadiga no encerramento. Restrições de vínculos continuam valendo em todas as etapas.',
 'Cada aquisição de Pacto Menor associa outro patrono, com nível próprio de 1 a 5, progressão decidida pelo mestre, reserva e carta separadas. Tags, reserva e cobrança menor permanecem nos dois lados; só o favor menor exige o lado A. Virar não repete recursos iniciais nem reinicia limites por cena.',
 'Sinergias de exílio voluntário de Oferenda e Favor com o Abismo foram mantidas expressamente. Cada origem de ganho respeita seu limite; ganhos adicionais não repetem seu próprio gatilho. Não há exceção nova para recuperar habilidades exiladas.',
 'A entrada inteira da Fênix, incluindo efeitos, valores, pendências e cobranças em aberto, foi preservada. Nenhuma restrição nova exige Fogo para usar Absorver as Chamas; permanece F + 2X.'
]
rules['testes_prioritarios']=[s for s in rules['testes_prioritarios'] if 'permanente só' not in s]

for data,ref in [(pacts,'referencia_regras'),(skills,'regras')]:
 data['versao']=3; data[ref]='classes/dados/bruxo/regras_propostas_lote_v03.json'
 data['estado']='revisao_autorizada_aplicada_sem_playtest'
rules['versao']=3;rules['estado']='ajustes_da_revisao_aplicados_conforme_autorizacao'
log={'data':'2026-10-27','estado':'aplicado','origem':'Autorização do autor para aplicar o parecer, preservando Fênix e cobrança aberta.','fenix_preservada_integralmente':True,'escolhas_editoriais':['Peso mantém Imobilizar e acrescenta 1 Atordoamento temporário.','Mesa aprimora também Devorar e restringe remoções próprias de Fadiga durante a cobrança.','Suspensão ampliada, com exceção integral da Fênix.','Conjuração mantida apenas onde já explícita; classificação arcana não cria tag nova.','Intercessão autoriza uma repetição imediata de reação na janela original.','Descanso funciona também em virada manual.','Sinergias de exílio com Abismo mantidas.','Inverno considera qualquer turno, sem estender automaticamente a obrigação.'],'ajustes_por_entrada':[],'testes_de_equilibrio':'Permanecem pendentes; observações de playtest não foram convertidas em nerfs automáticos.'}
oldp={x['id']:x for x in read('novos_pactos_v02.json')['patronos']}
oldg={x['id']:x for x in read('habilidades_gerais_v02.json')['cartas']}
for entries,old in [(pacts['patronos'],oldp),(skills['cartas'],oldg)]:
 for x in entries:
  if x!=old[x['id']]: log['ajustes_por_entrada'].append({'id':x['id'],'nome':x['nome']})
assert p['BR-P00']==original_fenix
assert len(pacts['patronos'])==10 and len(skills['cartas'])==18
assert sum(len(c['lados']) for c in skills['cartas'])==30
for name,data in [('novos_pactos_v03.json',pacts),('habilidades_gerais_v03.json',skills),('regras_propostas_lote_v03.json',rules),('ajustes_aplicados_v03.json',log)]: write(name,data)

registry_path=ROOT/'organizacao/especialidades/classes.json'
registry=json.loads(registry_path.read_text(encoding='utf-8'))
dev=registry['classe_em_desenvolvimento'];old=dev['lote_proposto']
if old.get('versao')==2: dev.setdefault('historico_lotes',{})['v02']=copy.deepcopy(old)
dev['lote_proposto'].update(versao=3,estado='revisao_autorizada_aplicada_sem_playtest',dados_patronos='classes/dados/bruxo/novos_pactos_v03.json',dados_gerais='classes/dados/bruxo/habilidades_gerais_v03.json',relatorio='outputs/01a17d39-9806-7153-9510-d82d1e7aaeea/classes/Bruxo_Pactos_e_Habilidades_Proposta_v03.html')
dev['revisao']['estado']='ajustes_aplicados_com_excecao_fenix_preservada'
dev['revisao']['aplicacao']='classes/dados/bruxo/ajustes_aplicados_v03.json'
registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'patronos':10,'habilidades_gerais':18,'fenix_inalterada':p['BR-P00']==original_fenix,'entradas_ajustadas':len(log['ajustes_por_entrada'])},ensure_ascii=False))
