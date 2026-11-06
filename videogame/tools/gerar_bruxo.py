"""Gera data/cartas/bruxo.json: a classe Bruxo da "Proposta v02" do Lucas (27/10/2026).

10 pactos (carta de herói do patrono + carta de pacto + habilidade inicial A/B) e 18 cartas
gerais (9 A/B de 1 XP, 6 meias de ½ XP, 3 A/B de 2 XP). Os textos são os do documento;
"custo" segue o formato do exportador da planilha (tools/exportar_cartas.py).

Uso: python3 tools/gerar_bruxo.py data/cartas/bruxo.json
"""
import json, re, sys, unicodedata


def slug(t):
    s = unicodedata.normalize('NFKD', t.lower())
    s = ''.join(c for c in s if not unicodedata.combining(c))
    return re.sub(r'[^a-z0-9]+', '-', s).strip('-')


def custo(texto):
    """'1 de Fadiga, 1 Pacto e Ação de Movimento: ...' -> custo no formato da planilha."""
    cab = texto.split(':')[0] if ':' in texto[:90] else ''
    m = re.search(r'(\d+) de Fadiga', cab)
    acao = None
    if 'Ação Padrão' in cab:
        acao = 'padrao'
    elif 'Ação de Movimento' in cab:
        acao = 'movimento'
    elif 'Reação' in cab:
        acao = 'reacao'
    p = re.search(r'(\d+|X) Pactos?', cab)
    outros = []
    if p:
        outros.append('%s Pacto(s)' % p.group(1))
    return {'fadiga': int(m.group(1)) if m else 0, 'acao': acao, 'outros': outros, 'permanente': '',
            'efeito': texto.split(':', 1)[1].strip() if cab else texto}


def lado(nome, texto, limite, tags):
    return {'nome': nome, 'tags': tags, 'texto': texto, 'limite_fadiga': limite, 'custo': custo(texto)}


# --- Os dez pactos ------------------------------------------------------------------------
# (id, nome do pacto, patrono, tags, ciclo, heroi{ativada, desencadeada}, cumprimento, cobrança,
#  descumprimento, reparação, inicial (nome A, texto A, limite A, nome B, texto B, limite B), menor, cobrança menor)
PACTOS = [
    ('fenix', 'Pacto da Fênix', 'A Fênix', ['Fogo', 'Fênix'],
     'Queimar → contribuir para a morte de monstros → ganhar Pacto → escolher entre explosão e recuperação.',
     'Gaste X fichas de Pacto: cure 3X de um alvo em alcance curto. A cura segue a regra normal de cura e exílio.',
     'Cada ficha de Fogo causa 2 de dano em vez de 1, independentemente de quem a colocou (inclui Fogo de outras fontes e Fogo hostil).',
     'Ganhe 1 ficha de Pacto ao presenciar a morte de um monstro pela qual você tenha sido responsável. Não é necessário dar o golpe final.',
     'Matar monstros. Prazo e quantidade ainda serão definidos.', 'Em aberto.', 'Ainda não definida.',
     ('Ave Fênix', '1 de Fadiga, Ação Padrão: faça um ataque mágico com seu foco contra um alvo em alcance curto, somando Espírito ao dano. Se acertar, coloque 1 ficha de Fogo no alvo e em cada inimigo adjacente a ele. Ao usar esta magia, você pode gastar X fichas de Pacto: se acertar, +2X de dano no alvo principal e 1 + 2X de dano direto em cada inimigo adjacente a ele.', 2,
      'Absorver as Chamas', '2 de Fadiga, Ação Padrão: remova todas as fichas de Fogo em alcance curto. Você cura F + 2X: F é o número de fichas de Fogo removidas e X o de fichas de Pacto gastas (X pode ser zero). Siga a regra normal de cura e exílio.', 4),
     'Uma vez no seu turno, 1 Pacto da reserva menor da Fênix: depois de acertar uma magia concedida pelo pacto pleno, cause +1 de dano de Fogo em um único alvo atingido.',
     'Depende de definição futura.', 4),
    ('abismo', 'Pacto do Abismo', 'Malgor, o Credor do Último Fôlego', ['Infernal', 'Abismo'],
     'Exilar voluntariamente → ganhar Pacto e potência → arriscar o 21 → pagar a cobrança do estouro.',
     '2 Pactos: após estourar e antes de comprar a carta final, olhe as 3 cartas do topo do seu baralho. Escolha uma como carta final e exile as demais. Apenas uma intervenção deste pacto na carta final por teste.',
     'Uma vez no seu turno, depois de resolver uma magia concedida por este pacto em cujo custo você exilou cartas do baralho, retire 1 de Fadiga daquela magia.',
     'Uma vez no seu turno, depois de resolver uma habilidade em cujo custo você exilou voluntariamente uma ou mais cartas comuns, ganhe 1 Pacto.',
     'Depois de um estouro, a carta final que determinou seu resultado vai para o exílio ao terminar o teste, em vez do descarte.',
     'Recusar essa cobrança suspende o pacto.', 'Exile 2 cartas do topo do seu baralho (não gera Pacto).',
     ('Sangrar o Véu', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco em alcance curto, causando dano Necrótico. Como custo adicional, antes de comprar as cartas do ataque, você pode exilar até Espírito cartas do topo do seu baralho. Se acertar, cause +2 de dano por carta assim exilada.', 2,
      'Última Oferta', '2 de Fadiga, Reação: depois de estourar uma defesa e comprar sua carta final, exile essa carta e compre uma substituta. Use o novo valor. Apenas uma intervenção deste pacto na carta final por teste.', 3),
     'Uma vez por cena, 1 Pacto: depois de estourar e comprar a carta final, exile-a e compre outra para determinar o resultado.',
     'Depois de estourar, a carta final do teste vai ao exílio ao terminar o teste.', 4),
    ('ultima-porta', 'Pacto da Última Porta', 'A Sentinela que Nunca Recuou', ['Luz', 'Juramento'],
     'Jurar proteção → assumir dano real → ganhar Pacto → escolher entre nova proteção e retaliação.',
     'X Pactos, Reação: quando um ataque inimigo causar dano ao protegido em alcance curto, reduza esse dano em 3X antes de distribuí-lo entre armadura, escudo e baralho.',
     'Uma vez por rodada, depois de receber dano de um ataque no lugar do protegido, se estiver adjacente a ele, vocês podem mover-se 1 quadrado cada, sem provocar ataques de oportunidade, terminando adjacentes.',
     'Uma vez por rodada, quando um ataque inimigo destinado ao protegido causar dano a você por ter assumido o ataque, ganhe 1 Pacto.',
     'Não termine voluntariamente seu turno com o protegido fora de alcance curto.',
     'Abandonar voluntariamente essa posição suspende o pacto.', 'Fique adjacente ao protegido e gaste uma ação Padrão renovando o juramento.',
     ('Vigília da Porta', '1 de Fadiga, Ação Padrão: se você ainda não tiver Guarda, coloque 1 ficha de Guarda em sua carta de herói. Se o protegido estiver em alcance curto e ainda não tiver Bloqueio, coloque 1 ficha de Bloqueio em uma carta dele.', 2,
      'Punho da Sentinela', '2 de Fadiga, Ação Padrão: faça um ataque mágico com foco, causando dano Radiante, contra um inimigo em alcance curto que tenha atacado o protegido desde o fim de seu último turno. Se acertar, some novamente seu Espírito ao dano.', 3),
     '1 Pacto, Reação: reduza em 2 o dano de um ataque contra um aliado adjacente a você, antes da distribuição do dano.',
     'Depois de usar o benefício menor, até o fim de seu próximo turno, não termine voluntariamente fora de alcance curto do aliado que protegeu.', 4),
    ('olho-descoberto', 'Pacto do Olho Descoberto', 'A Testemunha Sem Rosto', ['Luz', 'Revelação'],
     'Marcar → enxergar a aposta inimiga → inverter a ordem de decisão → colher o erro do adversário.',
     '1 Pacto, Reação: quando um inimigo em alcance curto colocar a carta Fechada num teste de que você participa, revele-a.',
     'Uma vez por rodada, depois de vencer um ataque ou defesa contra um inimigo cuja carta Fechada esteja revelada, ganhe 1 ficha de Foco.',
     'Uma vez por rodada, quando um inimigo Marcado estourar um ataque ou defesa contra você, ganhe 1 Pacto.',
     'Não minta deliberadamente enquanto este for seu pacto pleno.', 'Mentir deliberadamente suspende o pacto.',
     'Entregue a um adversário uma informação verdadeira que lhe conceda vantagem real, reconhecida pelo mestre.',
     ('Olhar que Despe', '1 de Fadiga, Ação de Movimento: escolha uma criatura em alcance curto. Faça um teste contestado de Espírito contra Mentira do alvo. Se vencer, coloque 1 ficha de Marcação nele.', 2,
      'Veredito Antecipado', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco, causando dano Radiante, contra um inimigo Marcado em alcance curto. O defensor conclui o teste antes de você decidir se puxa mais cartas. Você ainda pode estourar normalmente.', 3),
     '1 Pacto, Reação: durante um ataque que você esteja fazendo contra um inimigo em alcance curto, olhe a carta Fechada dele.',
     'Não minta deliberadamente enquanto este vínculo estiver associado à carta de Pacto Menor.', 4),
    ('caminhos-roubados', 'Pacto dos Caminhos Roubados', 'A Serpente Entre as Portas', ['Ar', 'Limiar'],
     'Deslocar um inimigo para o alcance de um aliado → ganhar Pacto → trocar posições e abrir rotas.',
     '1 Pacto, Reação: quando um aliado em alcance curto for escolhido como alvo de um ataque, ele pode mover-se 1 quadrado, ignorando impedimento e sem provocar ataques de oportunidade.',
     'Uma vez por turno, depois que você deslocar um inimigo, você pode mover-se 1 quadrado, ignorando impedimento e sem provocar ataques de oportunidade.',
     'Uma vez no seu turno, depois de deslocar um inimigo para um quadrado adjacente a um aliado que antes não estava adjacente a ele, ganhe 1 Pacto.',
     'Depois de usar uma magia deste pacto, termine o turno em um quadrado diferente daquele em que o começou, se houver deslocamento legal disponível.',
     'Optar por permanecer suspende o pacto.', 'Termine um turno em um quadrado diferente do inicial após usar deslocamento normal.',
     ('Mão Além do Limiar', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco em alcance curto, causando dano de Concussão. Se acertar, desloque o alvo 2 quadrados em linha reta em sua direção ou para longe de você. Pode gastar X Pactos para aumentar esse deslocamento em X quadrados.', 2,
      'Passagem Indevida', '1 de Fadiga e 1 Pacto, Ação de Movimento: troque de lugar com um aliado que você possa ver em alcance curto. Em vez de aliado, pode escolher um inimigo e pagar 2 Pactos: faça um teste contestado de Espírito contra Espírito dele; se vencer, troquem de lugar.', 3),
     '1 Pacto, Ação de Movimento: mova-se 1 quadrado ignorando impedimento e sem provocar ataques de oportunidade.',
     'Depois de usar o benefício menor, não retorne voluntariamente ao quadrado em que começou o turno antes do fim dele.', 4),
    ('grilhoes-vivos', 'Pacto dos Grilhões Vivos', 'O Carcereiro Sem Chave', ['Trevas', 'Prisão'],
     'Prender → converter a prisão em pressão → ganhar Pacto quando o inimigo paga para escapar → punir a libertação.',
     '1 Pacto, Reação: depois que um inimigo em alcance curto remover Imobilizar ou Atordoamento colocado por você, coloque 1 ficha de Penalidade nele.',
     'Uma vez por rodada, quando um inimigo gastar uma ação para remover Imobilizar ou Atordoamento colocado por você, ganhe 1 ficha de Foco.',
     'Uma vez por rodada, quando um inimigo gastar uma ação para remover Imobilizar ou Atordoamento colocado por você, ganhe 1 Pacto.',
     'Aceite rendições oferecidas de boa-fé e não execute nem autorize a execução de quem esteja sob sua guarda.',
     'Violar essa obrigação suspende o pacto.', 'Liberte ou proteja um prisioneiro cuja sobrevivência imponha um custo real a você, reconhecido pelo mestre.',
     ('Grilhão de Sombra', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco em alcance curto, causando dano Necrótico. Se causar dano, o defensor recebe 1 ficha de Imobilizar. Você pode gastar 1 Pacto para colocar também 1 ficha de Atormentado.', 2,
      'Peso da Sentença', '2 de Fadiga e 1 Pacto, Ação Padrão: escolha um inimigo em alcance curto que tenha Imobilizar colocado por você. Faça um teste contestado de Espírito contra Espírito dele. Se vencer, remova 1 dessas fichas de Imobilizar e coloque 1 ficha de Atordoamento.', 3),
     '1 Pacto, Reação: depois que um aliado acertar um ataque contra um inimigo adjacente a você, coloque 1 ficha de Penalidade no defensor.',
     'Aceite rendições de boa-fé e não execute quem esteja sob sua guarda.', 4),
    ('mesa-vazia', 'Pacto da Mesa Vazia', 'Vorga, a Boca sob o Lago', ['Fome', 'Dreno'],
     'Atormentar → deixar a Fadiga inimiga crescer → devorar o esforço acumulado → sustentar novas conjurações.',
     'X Pactos: antes de comprar as cartas de um ataque mágico concedido por este pacto contra um alvo com Atormentado, aumente em 2X o dano no acerto. Se o ataque causar dano, você pode curar X.',
     'Uma vez por rodada, depois de uma magia deste pacto remover Fadiga de um inimigo, retire 1 de Fadiga de uma de suas outras cartas.',
     'Uma vez por rodada, depois de uma magia concedida por este pacto remover pelo menos 2 fichas de Fadiga de um inimigo, ganhe 1 Pacto.',
     'Quando remover Fadiga de um inimigo com uma magia deste pacto, até o fim de seu próximo turno você não pode receber voluntariamente um efeito de outro personagem que remova sua Fadiga.',
     'Aceitar voluntariamente essa remoção externa suspende o pacto.', 'Gaste uma ação Padrão e descarte 2 cartas da mão.',
     ('Fermento da Fome', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco em alcance curto, causando dano de Dreno. Se acertar, coloque 1 ficha de Atormentado no defensor.', 2,
      'Devorar o Esforço', '1 de Fadiga, Ação Padrão: escolha um inimigo em alcance curto que tenha Fadiga. Faça um teste contestado de Espírito contra Espírito dele. Se vencer, remova até Espírito fichas de Fadiga do alvo e cause 2 de dano de Dreno por ficha removida.', 4),
     'Uma vez por turno, 1 Pacto: depois de acertar um ataque mágico, se o defensor tiver Fadiga, remova 1 dessas fichas e retire 1 de Fadiga de uma de suas outras cartas.',
     'Depois de usar o benefício menor, até o fim de seu próximo turno não aceite voluntariamente remoção de Fadiga causada por outro personagem.', 4),
    ('trovao-cativo', 'Pacto do Trovão Cativo', 'A Serpente de Cobre que Circunda a Tormenta', ['Raio', 'Tempestade'],
     'Conjurar → encher uma carta → ganhar Pacto e reação → consumir a Fadiga em uma descarga.',
     'X Pactos, Reação: depois de uma magia de Raio concedida por este pacto acertar um inimigo, cause 2X de dano de Raio a um segundo inimigo adjacente a ele, sem novo teste.',
     'Uma vez por rodada, quando pagar a Fadiga de uma magia deste pacto fizer uma carta sua chegar exatamente ao limite, se você não tiver nenhuma ficha de Reação, ganhe 1 ficha de Reação.',
     'Uma vez no seu turno, quando pagar a Fadiga de uma magia concedida por este pacto fizer uma carta sua chegar exatamente ao limite, ganhe 1 Pacto.',
     'Se conjurou uma magia deste pacto no turno, preserve ao menos 1 ficha de Fadiga entre sua carta de herói e a habilidade inicial ao encerrar o turno.',
     'Optar por terminar o turno sem essa carga suspende o pacto.', '1 de Fadiga, Ação de Movimento: coloque essa Fadiga em sua carta de herói ou habilidade inicial.',
     ('Fagulha Cativa', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco em alcance médio, causando dano de Raio. Esta magia tem Conjuração: você pode pagar sua Fadiga em outra carta sua com capacidade livre.', 2,
      'Descarregar a Tormenta', '1 de Fadiga, Reação: depois que um inimigo em alcance curto concluir um ataque contra você, faça um ataque mágico de resposta contra ele com foco, causando dano de Raio. Como custo adicional, remova de suas outras cartas até Espírito fichas de Fadiga. Se acertar, cause +2 de dano por ficha assim removida.', 4),
     'Uma vez por turno, 1 Pacto: depois de resolver uma magia que cause dano de Raio, mova 1 ficha de Fadiga da carta usada para outra carta sua que tenha espaço livre.',
     'Após usar o benefício menor, conserve ao menos 1 ficha de Fadiga em uma de suas cartas até o fim de seu próximo turno.', 4),
    ('sonhos-roubados', 'Pacto dos Sonhos Roubados', 'Niméria, a Dama dos Sonhos Inacabados', ['Trevas', 'Sonho'],
     'Atormentar → esperar o inimigo acumular Fadiga ou virar a carta → colher Pacto ou Foco → consumir o pesadelo para formar uma mão melhor.',
     '2 Pactos, Reação: quando um inimigo em alcance curto que tenha Atormentado colocado por você escolher o alvo de um ataque, faça um teste contestado de Espírito contra Espírito dele. Se vencer, coloque 1 Confusão nele antes de resolver a escolha de alvo.',
     'Uma vez por rodada, depois que um inimigo remover Atormentado colocado por você, ganhe 1 Foco.',
     'Uma vez por rodada, quando um inimigo receber Fadiga de uma ficha de Atormentado colocada por você, ganhe 1 Pacto.',
     'Depois de comprar sua mão inicial da cena e antes de usar benefícios deste pacto, escolha 1 carta dessa mão e exile-a como o sonho entregue à patrona.',
     'Recusar a entrega suspende o pacto.', 'Ação Padrão: exile 1 carta de sua mão e entregue o sonho atrasado.',
     ('Semeadura do Pesadelo', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco em alcance curto, causando dano Psíquico. Se causar dano, coloque 1 Atormentado no defensor. Esta magia não coloca outro Atormentado se o defensor já tiver um colocado por você.', 2,
      'Colher o Sonho', '2 de Fadiga, Ação Padrão: escolha um inimigo em alcance curto que tenha Atormentado colocado por você e remova 1 dessas fichas. Olhe as 3 cartas do topo de seu baralho, coloque 2 delas em sua mão e as demais no fundo do baralho. Antes de olhar, você pode gastar X Pactos para olhar X cartas adicionais.', 3),
     '1 Pacto, Reação: quando um inimigo em alcance curto que tenha Atormentado escolher você como alvo de um ataque, faça um teste contestado de Espírito contra Espírito dele. Se vencer, ele recebe 1 Confusão.',
     'Depois da mão inicial, antes de usar este benefício menor, exile 1 carta da mão como sonho entregue.', 4),
    ('inverno-imovel', 'Pacto do Inverno Imóvel', 'A Rainha da Última Geada', ['Gelo', 'Conservação'],
     'Conservar Fadiga → ganhar Pacto → concentrar a Fadiga num disparo → sustentar a posição ou quebrar a camada virando a carta.',
     '1 Pacto: transfira 1 Fadiga de outra carta sua para esta carta de herói, apenas se houver espaço. Uma vez no seu turno.',
     'Uma vez no seu turno, quando a habilidade inicial deste pacto atingir seu limite de Fadiga após a resolução da magia, se você não tiver Bloqueio, coloque 1 Bloqueio em sua carta de herói.',
     'Uma vez por seu turno numa cena de conflito real, se tiver pelo menos 1 Fadiga numa carta e abrir mão da remoção normal de 1 Fadiga do fim do turno, ganhe 1 Pacto.',
     'Em um turno em que gastar fichas deste pacto, não pode ter se deslocado voluntariamente nem voltar a se deslocar voluntariamente antes de encerrar esse turno.',
     'Escolher mover-se e gastar Pacto no mesmo turno suspende ganhos e gastos da reserva.',
     'Encerre um turno sem se mover, com pelo menos 1 Fadiga na habilidade inicial, abrindo mão da recuperação normal de fim de turno.',
     ('Sopro da Geada', '1 de Fadiga, Ação Padrão: faça um ataque mágico com foco em alcance curto, causando dano de Gelo. Se causar dano, a próxima ação de Movimento que o defensor usar até o início do seu próximo turno rende apenas 1 quadrado.', 2,
      'Coração do Inverno', '2 de Fadiga, Ação Padrão: depois de pagar a Fadiga desta magia, você pode transferir até 2 Fadigas de uma outra carta sua para esta carta, sem ultrapassar seu limite. Faça um ataque mágico com foco em alcance curto, causando dano de Gelo. Se acertar, cause +2 de dano por Fadiga transferida.', 4),
     '1 Pacto, Reação: depois que um inimigo em alcance curto causar dano a você com um ataque, a próxima ação de Movimento que ele usar até o início do seu próximo turno rende apenas 1 quadrado.',
     'Depois de usar o benefício menor, no fim do seu próximo turno abra mão da recuperação normal de 1 Fadiga se tiver alguma Fadiga que pudesse remover.', 4),
]

# --- Cartas gerais (18) -----------------------------------------------------------------------
GERAIS_1XP = [
    ('VÍNCULOS', 'Pacto Menor', 'Ao escolher esta carta, associe um patrono secundário. Suas tags, a reserva menor e a cobrança menor desse patrono permanecem nos dois lados. No começo da cena, a reserva menor recebe N Pactos. Enquanto este lado estiver revelado, você pode usar somente o benefício menor dele. Não recebe a habilidade inicial A/B nem os efeitos de herói.', 2,
     'Procuração', '2 Pactos da reserva menor, Ação de Movimento: retire 1 de Fadiga da habilidade inicial de seu pacto pleno. Uma vez por turno. O benefício menor fica inativo neste lado.', 2),
    ('VÍNCULOS', 'Manter o Canal', '1 de Fadiga, 1 Pacto e Reação: quando um efeito inimigo faria você virar a habilidade inicial desse pacto, mantenha a face atual e coloque 1 ficha de Atormentado nela.', 2,
     'Desatar o Nó', '1 de Fadiga, 1 Pacto e Ação de Movimento: vire a habilidade inicial desse pacto e mova-se 1 quadrado ignorando impedimento e sem provocar ataques de oportunidade.', 2),
    ('VÍNCULOS', 'Patrono Presente', '1 de Fadiga, 1 Pacto e Reação: quando um efeito de uma criatura que você possa ver em alcance curto anularia uma magia concedida por esse pacto, faça um teste contestado de Espírito contra Espírito dessa criatura. Se vencer, sua magia continua sua resolução normal.', 2,
     'Canal sem Ruído', '1 de Fadiga e 1 Pacto: remova 1 ficha de Penalidade ou de Atormentado da habilidade inicial desse pacto, sem virá-la. Uma vez por turno.', 2),
    ('PREÇO E PODER', 'Oferenda Selada', 'Exile 2 cartas comuns do seu descarte, Ação de Movimento: ganhe 2 Pactos em uma reserva sua que não esteja suspensa. Uma vez por cena.', 2,
     'Resgatar o Penhor', '2 Pactos de uma reserva sua, Ação Padrão: devolva 1 carta comum do seu exílio para o descarte.', 2),
    ('PREÇO E PODER', 'Testemunho do Feito', 'Uma vez por turno, depois de receber Pacto pelo gatilho de cumprimento de seu patrono, você pode descartar 1 carta da mão para ganhar 1 Pacto adicional naquela reserva.', 2,
     'O Patrono Lembra', '1 de Fadiga e 1 Pacto: depois de resolver um ataque mágico estourado concedido por esse pacto, devolva à mão 1 carta usada naquele teste que esteja no seu descarte. Uma vez por teste.', 2),
    ('PREÇO E PODER', 'Emprestar a Vontade', '1 de Fadiga: antes de realizar um teste de perícia cuja tarefa avance diretamente o cumprimento da cobrança de seu pacto pleno, use Espírito no lugar do atributo pedido. O mestre confirma a relação com a cobrança. Uma vez por cena.', 2,
     'Ouvir a Reprimenda', '1 de Fadiga e 1 Pacto da reserva plena: depois de falhar em um teste de perícia cuja tarefa avance diretamente o cumprimento da cobrança desse pacto, compre 2 cartas para a mão. Uma vez por cena.', 2),
    ('POTÊNCIA ESPECIALIZADA', 'Concentrar a Manifestação', '1 de Fadiga e 1 Pacto: antes de conjurar uma magia concedida por esse pacto que afetaria dois ou mais inimigos, escolha somente um deles. Ignore os efeitos nos demais e some novamente seu Espírito ao dano direto da magia contra o escolhido.', 2,
     'Estender o Sinal', '2 de Fadiga e 1 Pacto: depois de sua magia desse pacto acertar e colocar fichas no alvo principal, faça um novo teste de ataque mágico contra outro inimigo adjacente a ele. Se acertar, coloque 1 ficha de um dos tipos que a magia colocou no primeiro alvo.', 2),
    ('POTÊNCIA ESPECIALIZADA', 'Presságio do Patrono', '1 de Fadiga, Ação de Movimento: imediatamente antes de começar um ataque mágico concedido por seu pacto pleno, faça scry 3.', 1,
     'Ler o Destino', '1 de Fadiga: depois de revelar as duas cartas iniciais de um ataque mágico concedido por seu pacto pleno, coloque a carta Aberta no fundo do baralho e revele uma substituta. Uma vez por teste.', 1),
    ('POTÊNCIA ESPECIALIZADA', 'Nominar o Devedor', '1 de Fadiga, Ação de Movimento: escolha um inimigo em alcance curto. Faça um teste contestado de Espírito contra Espírito dele. Se vencer, coloque 1 ficha de Marcação no alvo.', 2,
     'Executar a Cláusula', '1 de Fadiga e 1 Pacto: num ataque mágico concedido por esse pacto contra um inimigo Marcado, depois das duas cartas iniciais do defensor, coloque uma delas que esteja revelada no fundo do baralho dele e revele uma substituta. Uma vez por teste.', 2),
]
MEIAS = [
    ('Ouvir o Chamado', '1 de Fadiga: faça scry 1 imediatamente antes de comprar as cartas de um ataque mágico concedido por seu pacto pleno. Uma vez por teste.', 1),
    ('Selo de Continuidade', '1 Pacto: no fim do seu turno, retire 1 de Fadiga adicional da habilidade inicial daquele pacto. Uma vez por turno.', 1),
    ('Segredo Entre as Cartas', '1 Pacto: antes de comprar as duas cartas iniciais de um ataque mágico concedido por aquele pacto, compre ambas ocultas, olhe-as e escolha qual revelar como carta Aberta. Uma vez por teste.', 1),
    ('Favor de Última Hora', 'Exile 1 carta do topo do seu baralho: ganhe 1 Pacto na reserva de seu pacto pleno, se ele não estiver suspenso. Uma vez por cena.', 1),
    ('Passo do Emissário', '1 Pacto: após resolver uma magia concedida por aquele pacto, mova-se 1 quadrado ignorando impedimento e sem provocar ataques de oportunidade. Uma vez por conjuração.', 1),
    ('O Patrono Não Desperdiça', '1 Pacto: ao errar um ataque mágico concedido por aquele pacto, devolva ao fundo do baralho 1 carta usada nesse teste que esteja no seu descarte. Uma vez por ataque.', 1),
]
GERAIS_2XP = [
    ('Manifestação Dupla', '2 de Fadiga, 3 Pactos e Ação Padrão: conjure a face revelada da habilidade inicial desse pacto, pagando seus recursos normalmente, sem gastar sua ação. Depois, vire aquela carta. Até o início de seu próximo turno, você pode conjurar uma vez a outra face, pagando os recursos sem gastar sua ação.', 4,
     'Descanso da Voz', 'Ao virar para este lado, você pode exilar 1 carta do seu descarte para retirar até 2 de Fadiga da habilidade inicial do pacto.', 2),
    ('Assinatura Vital', 'Uma vez por turno, ao pagar um custo de Pacto de uma magia concedida por aquele pacto, você pode substituir uma das fichas por exilar 1 carta do topo do baralho. Pelo menos 1 ficha de Pacto precisa ser realmente gasta.', 4,
     'Quitar a Dívida', '3 Pactos e Ação Padrão: retire até 3 de Fadiga de uma única outra carta que conceda uma magia daquele pacto. Depois, vire esta carta.', 4),
    ('Intercessão do Patrono', '2 Pactos, exile esta carta: depois de falhar em um ataque da habilidade inicial daquele pacto, você pode fazer uma nova conjuração da mesma face, pagando novamente seus custos, sem gastar outra ação. A carta fica indisponível pelo resto da cena.', 0,
     'Retirar o Nome', '2 Pactos, exile esta carta e Reação: depois de aplicar as resistências a um ataque que causou dano a você, mas antes de distribuí-lo, converta em Fadiga a parte que conseguir acomodar nos espaços livres de suas outras cartas. A carta fica indisponível pelo resto da cena.', 0),
]


def main(saida):
    herois, habilidades, pactos = [], [], {}
    for (pid, nome, patrono, tags, ciclo, ativada, desencadeada, cumprimento, cobranca, descump, reparacao, ini, menor, cob_menor, lim) in PACTOS:
        hid = 'classe.bruxo.heroi.' + slug(patrono)
        iid = 'pacto.%s.inicial' % pid
        herois.append({'id': hid, 'fonte': 'classe', 'entidade': 'Bruxo', 'nome': patrono,
                       'descricao': '%s · %s. %s' % (nome, ' · '.join(tags), ciclo),
                       'passiva': 'Carta do %s. Concede a tag Pacto (e as tags %s).' % (nome, ' e '.join(tags)),
                       'ativada': ativada, 'desencadeada': desencadeada,
                       'critico': 'Ganhe fichas de Pacto iguais ao nível deste pacto.',
                       'custo_ativada': custo(ativada), 'limite_fadiga': lim, 'pacto': pid, 'impressao': 'bruxo-v02'})
        a_nome, a_txt, a_lim, b_nome, b_txt, b_lim = ini
        t_ini = ['Magia', 'Pacto'] + tags
        habilidades.append({'id': iid, 'fonte': 'pacto', 'entidade': 'Bruxo (pacto)', 'grupo': nome, 'xp': 0, 'meia_carta': False,
                            'lados': [lado(a_nome, a_txt, a_lim, t_ini + (['Conjuração'] if pid == 'trovao-cativo' else [])),
                                      lado(b_nome, b_txt, b_lim, t_ini)], 'pacto': pid, 'impressao': 'bruxo-v02'})
        pactos[pid] = {'nome': nome, 'patrono': patrono, 'tags': tags, 'heroi': hid, 'inicial': iid, 'ciclo': ciclo,
                       'cumprimento': cumprimento, 'cobranca': cobranca, 'descumprimento': descump, 'reparacao': reparacao,
                       'menor': menor, 'cobranca_menor': cob_menor}
    for (grupo, an, at, al, bn, bt, bl) in GERAIS_1XP:
        habilidades.append({'id': 'classe.bruxo.' + slug(an), 'fonte': 'classe', 'entidade': 'Bruxo',
                            'grupo': 'ESTRATÉGIA · ' + grupo, 'xp': 1, 'meia_carta': False,
                            'lados': [lado(an, at, al, ['Pacto']), lado(bn, bt, bl, ['Pacto'])], 'impressao': 'bruxo-v02'})
    for (n, t, l) in MEIAS:
        habilidades.append({'id': 'classe.bruxo.' + slug(n), 'fonte': 'classe', 'entidade': 'Bruxo', 'grupo': 'MEIAS CARTAS',
                            'xp': 1, 'meia_carta': True, 'lados': [lado(n, t, l, ['Pacto', 'Meia Carta']), None], 'impressao': 'bruxo-v02'})
    for (an, at, al, bn, bt, bl) in GERAIS_2XP:
        habilidades.append({'id': 'classe.bruxo.' + slug(an), 'fonte': 'classe', 'entidade': 'Bruxo', 'grupo': 'CARTAS DE 2 XP',
                            'xp': 2, 'meia_carta': False,
                            'lados': [lado(an, at, al, ['Pacto']), lado(bn, bt, bl, ['Pacto'])], 'impressao': 'bruxo-v02'})
    json.dump({'fonte': 'Bruxo_Pactos_e_Habilidades_Proposta_v02 (27/10/2026)', 'herois': herois, 'habilidades': habilidades,
               'pactos': pactos}, open(saida, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(len(herois), 'heróis,', len(habilidades), 'cartas,', len(pactos), 'pactos ->', saida)


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'data/cartas/bruxo.json')
