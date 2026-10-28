## Quais lados de carta já têm efeito programado, e como cada um é usado.
## A chave é o nome do lado em forma de "slug" (ex.: "ombro-de-ferro").
##
## uso:
##   "passiva"    sempre ativa enquanto o lado estiver para cima
##   "ativada"    o jogador ativa pagando o custo (fadiga + ação, lidos da carta)
##   "reacao"     oferecida pelo jogo quando o gatilho acontece
##   "ao_virar"   dispara quando a carta é virada para este lado
##   "na_mesa"    ativada durante um teste de 21
##   "fora"       efeito de perícia ou fora de combate: sem efeito na batalha (por enquanto)
## alvo: "nenhum", "inimigo_corpo" (ataque corpo a corpo), "inimigo_salto"
##       (anda 1 e ataca), "inimigo_investida" (anda até 3 e ataca)
extends RefCounted

const LADOS := {
	# Guerreiro · Tanque de Guerra
	"peso-da-muralha": {"uso": "ativada", "alvo": "nenhum"},
	"contragolpe-de-aco": {"uso": "ativada", "alvo": "inimigo_corpo"},
	"ombro-de-ferro": {"uso": "ativada", "alvo": "inimigo_salto"},
	"avalanche": {"uso": "ativada", "alvo": "inimigo_corpo"},
	# Guerreiro · Mestre das Posturas
	"postura-do-leao": {"uso": "passiva"},
	"postura-da-cascavel": {"uso": "reacao"},
	"postura-da-tartaruga": {"uso": "passiva"},
	"ombro-de-aco": {"uso": "passiva", "nota": "afeta aliados (sem efeito sozinho)"},
	"marcha-militar": {"uso": "ativada", "alvo": "nenhum", "nota": "sem terreno difícil nem interação ainda: dá 2 quadrados de movimento"},
	"romper-a-linha": {"uso": "ativada", "alvo": "nenhum"},
	# Guerreiro · Hoplita
	"lanca-em-riste": {"uso": "ativada", "alvo": "inimigo_corpo", "nota": "+1 por aliado adjacente (sem aliados ainda)"},
	"perfurar-e-recuar": {"uso": "ativada", "alvo": "inimigo_corpo"},
	# Guerreiro · Meia cartas
	"respirar-fundo": {"uso": "ativada", "alvo": "nenhum"},
	"firmar-os-pes": {"uso": "ativada", "alvo": "nenhum"},
	"reposicionar": {"uso": "ativada", "alvo": "nenhum"},
	"foco-marcial": {"uso": "na_mesa"},
	"segundo-folego": {"uso": "ativada", "alvo": "nenhum"},
	# Guerreiro · 2 XP
	"sangue-fervente": {"uso": "ativada", "alvo": "nenhum"},
	"segundo-vento": {"uso": "ao_virar"},
	"ancora": {"uso": "ativada", "alvo": "nenhum", "nota": "a parte de virar alvo no lugar de aliados ainda não tem uso"},
	"instinto-defensivo": {"uso": "ao_virar"},
	# Humano
	"parabola-intuitiva": {"uso": "passiva"},
	# Soldado
	"manutencao-do-equipamento": {"uso": "passiva"},
	# Lados de perícia / fora de combate (sem efeito na batalha por enquanto)
	"resistencia-do-corredor": {"uso": "fora", "nota": "a ação Correr ainda não existe"},
	"mente-maleavel": {"uso": "passiva", "nota": "as duas perícias são escolhidas na criação"},
	"persistencia-humana": {"uso": "reacao", "nota": "oferecida quando um teste de perícia falha"},
	"resposta-criativa": {"uso": "passiva"},
	"trabalho-em-equipe": {"uso": "fora", "nota": "a ação de ajudar ainda não existe"},
	"vigor-de-marcha": {"uso": "fora", "nota": "esforços prolongados e clima ainda não existem"},
	"olho-de-veterano": {"uso": "fora", "nota": "ainda não programado (fraquezas por tipo de dano já existem nos inimigos)"},
	"nervos-de-aco": {"uso": "passiva"},
	"irmaos-de-farda": {"uso": "fora", "nota": "fora de combate"},
	"postura-firme": {"uso": "passiva", "nota": "vantagem em testes marcados como comando"},
	# Elfo
	"visao-elfica": {"uso": "passiva", "nota": "vantagem em Percepção e enxerga no escuro como penumbra (o alcance longo como médio ainda não)"},
	"talento-com-o-arco": {"uso": "passiva", "nota": "sem desvantagem fora da faixa ideal do arco (cobertura ainda não existe)"},
	"saber-natural": {"uso": "ativada", "alvo": "aliado", "alcance": 1},
	"heranca-feerica": {"uso": "passiva"},
	"vigilia-elfica": {"uso": "fora", "nota": "descanso longo ainda não existe"},
	"maestria-de-uma-vida": {"uso": "passiva", "nota": "a perícia é escolhida na criação"},
	# Anão
	"olho-para-o-minerio": {"uso": "passiva", "nota": "vantagem em testes marcados como caverna"},
	"maos-de-forja": {"uso": "passiva", "nota": "funciona no descanso curto"},
	"forca-das-montanhas": {"uso": "passiva"},
	"constituicao-de-pedra": {"uso": "passiva", "nota": "imune a Veneno; −2 no dano de Fogo (Gelo e Raio ainda não existem)"},
	"filho-da-pedra": {"uso": "passiva", "nota": "enxerga no escuro como penumbra (localizar-se em cavernas fica para a exploração)"},
	"memoria-ancestral": {"uso": "passiva", "nota": "só a vantagem em História, Política e Religião"},
	# Halfling
	"sorte-dos-pequenos": {"uso": "passiva"},
	"azar-alheio": {"uso": "passiva", "nota": "usada sozinha no primeiro ataque inimigo que acertar você na cena"},
	"passos-leves": {"uso": "passiva"},
	"alvo-dificil": {"uso": "passiva"},
	"coragem-miuda": {"uso": "passiva"},
	"aconchego": {"uso": "passiva", "nota": "aplicada sozinha no fim do turno do aliado"},
	# Orc
	"golpe-selvagem": {"uso": "ativada", "alvo": "inimigo_corpo"},
	"sede-de-sangue": {"uso": "passiva"},
	"folego-feroz": {"uso": "ativada", "alvo": "nenhum", "nota": "descarta a carta de menor valor da mão (ou a do topo do baralho)"},
	"ignorar-a-dor": {"uso": "passiva", "nota": "sempre escolhe ignorar"},
	"presenca-aterradora": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4},
	"couro-grosso": {"uso": "ativada", "alvo": "nenhum"},
	# Bandido
	"maos-leves": {"uso": "fora", "nota": "agarrar ainda não existe"},
	"pes-no-telhado": {"uso": "ativada", "alvo": "nenhum"},
	"olhar-esperto": {"uso": "reacao", "nota": "oferecida quando um teste de procurar falha"},
	"astucia-de-rua": {"uso": "ativada", "alvo": "nenhum"},
	"contatos-do-submundo": {"uso": "fora", "nota": "fora de combate"},
	"giria-dos-ladroes": {"uso": "passiva", "nota": "vantagem em testes marcados como criminosos"},
	# Escravo
	"couro-duro": {"uso": "passiva"},
	"braco-de-labuta": {"uso": "passiva"},
	"atento-aos-desejos": {"uso": "passiva"},
	"aprendiz-silencioso": {"uso": "passiva", "nota": "as três perícias são escolhidas na criação"},
	"espirito-inquebravel": {"uso": "ativada", "alvo": "nenhum"},
	"passar-despercebido": {"uso": "passiva"},
	# Explorador
	"folego-de-viajante": {"uso": "passiva"},
	"passo-firme": {"uso": "passiva"},
	"senso-de-direcao": {"uso": "ativada", "alvo": "nenhum"},
	"erudito-das-estradas": {"uso": "passiva"},
	"forasteiro-bem-vindo": {"uso": "passiva", "nota": "em testes marcados como novo local"},
	"linguas-de-estrada": {"uso": "fora", "nota": "línguas ainda não existem"},
	# Fervoroso
	"resistencia-da-fe": {"uso": "passiva"},
	"crenca-da-provacao": {"uso": "passiva"},
	"fe-lapidada": {"uso": "na_mesa", "nota": "aparece quando um aliado faz um teste de Espírito"},
	"saber-sagrado": {"uso": "passiva"},
	"comunidade-da-fe": {"uso": "fora", "nota": "fora de combate"},
	"palavra-que-conforta": {"uso": "ativada", "alvo": "aliado", "alcance": 1, "sem_si": true},
	# Ladino
	"dedos-de-seda": {"uso": "passiva", "nota": "num teste de Ladinagem bem-sucedido, ganha 1 Preparo (sem a virada opcional)"},
	"por-um-triz": {"uso": "ativada", "alvo": "nenhum"},
	"ataque-furtivo": {"uso": "na_mesa", "nota": "durante o seu ataque: descarte Sombra, uma por vez (+ dano da arma cada)"},
	"bomba-de-fumaca": {"uso": "ativada", "alvo": "nenhum"},
	"passo-de-sombra": {"uso": "ativada", "alvo": "nenhum", "exige_fichas": {"Sombra": 2}},
	"assalto-do-gatuno": {"uso": "fora", "nota": "ainda não programado (roubo e Desarmado)"},
	"mas-veja-bem": {"uso": "passiva", "nota": "refaz um teste de Diplomacia ou Mentira que falhou (vira a carta)"},
	"olha-la": {"uso": "fora", "nota": "ainda não programado (Marcação e Penalidade em heróis)"},
	"finta": {"uso": "fora", "nota": "ainda não programado (vantagem no ataque)"},
	"lamina-na-manga": {"uso": "passiva"},
	"rede-de-contatos": {"uso": "fora", "nota": "fora de combate"},
	"escapulir": {"uso": "fora", "nota": "ainda não programado"},
	"truques-de-salao": {"uso": "fora", "nota": "fora de combate"},
	"fechadura-fantasma": {"uso": "fora", "nota": "ainda não programado"},
	"mancha-sombria": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 3, "exige_fichas": {"Sombra": 1}},
	"nevoa-ilusoria": {"uso": "ativada", "alvo": "area", "magia": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"gancho-fantasma": {"uso": "fora", "nota": "ainda não programado"},
	"adaga-fantasma": {"uso": "fora", "nota": "ainda não programado"},
	"olho-de-ladrao": {"uso": "fora", "nota": "fora de combate"},
	"pe-ligeiro": {"uso": "ativada", "alvo": "nenhum"},
	"lamina-rapida": {"uso": "ativada", "alvo": "nenhum"},
	"varinha-eletrizante": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 8},
	# Focos do PDF (cartas de item)
	"simbolo-sagrado": {"uso": "passiva"},
	"varinha-de-cristal": {"uso": "ativada", "alvo": "nenhum"},
	"cajado-do-aprendiz": {"uso": "ativada", "alvo": "nenhum"},
	"cajado-de-batalha": {"uso": "ativada", "alvo": "nenhum"},
	"orbe-de-concentracao": {"uso": "ativada", "alvo": "nenhum"},
	"orbe-de-protecao": {"uso": "ativada", "alvo": "aliado", "alcance": 1},
	"relicario-do-guardiao": {"uso": "ativada", "alvo": "aliado", "alcance": 4, "sem_si": true},
	"escrituras-scry": {"uso": "ativada", "alvo": "aliado", "alcance": 1},
	"escrituras-espirito": {"uso": "ativada", "alvo": "nenhum"},
	"rosario-da-devocao": {"uso": "ativada", "alvo": "nenhum", "exige_fichas": {"Ferimento": 1}},
	"empurrao-mistico": {"uso": "fora", "nota": "ainda não programado"},
	"torcer-a-lamina": {"uso": "ativada", "alvo": "nenhum"},
	"sumico": {"uso": "ativada", "alvo": "nenhum"},
	"nunca-visto": {"uso": "passiva"},
	"bote-fatal": {"uso": "passiva"},
	"sempre-um-plano": {"uso": "ativada", "opcoes": [
		{"id": "recuperar", "nome": "Recuperar consumível", "custo": {"fadiga": 0, "acao": "padrao"}, "alvo": "nenhum"},
		{"id": "comprar", "nome": "Comprar uma carta", "custo": {"fadiga": 2, "acao": null}, "alvo": "nenhum"}]},
	"adaptavel": {"uso": "fora", "nota": "ainda não programado"},
	"passo-espectral": {"uso": "fora", "nota": "ainda não programado (teleporte)"},
	"roubo-arcano": {"uso": "fora", "nota": "inimigos ainda não conjuram"},
	# Clérigo
	"toque-restaurador": {"uso": "ativada", "alvo": "aliado", "alcance": 1, "magia": true},
	"bencao-persistente": {"uso": "fim_turno", "magia": true, "nota": "oferecida na tela de fim do turno (Lucas, 0.20)"},
	"feixe-de-luz": {"uso": "ativada", "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 2, "magia": true},
	"golpe-da-punicao": {"uso": "ativada", "alvo": "inimigo_corpo"},
	"lanterna-da-fe": {"uso": "ativada", "alvo": "nenhum", "magia": true, "custo": {"fadiga": 1, "acao": null}, "nota": "a luz sai ao redor de você (o cone ainda não); precisa de uma mão livre"},
	"clarao-divino": {"uso": "ativada", "alvo": "nenhum", "magia": true},
	"agua-benta": {"uso": "ativada", "magia": true, "opcoes": [
		{"id": "remover", "nome": "Remover uma ficha", "custo": {"fadiga": 1, "acao": null}, "alvo": "aliado", "alcance": 1, "sem_si": true},
		{"id": "dano-sagrado", "nome": "2 de dano em morto-vivo/demônio", "custo": {"fadiga": 1, "acao": null}, "alvo": "inimigo_profano", "alcance": 1}]},
	"circulo-de-protecao": {"uso": "ativada", "alvo": "nenhum", "magia": true, "custo": {"fadiga": 2, "acao": null}, "nota": "você e aliados a até 4 quadrados"},
	"palavra-de-banimento": {"uso": "ativada", "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4, "magia": true},
	"expulsar": {"uso": "ativada", "alvo": "inimigo_corpo_qualquer", "magia": true, "nota": "teste de Espírito automático contra o Espírito do inimigo"},
	"voz-do-exorcista": {"uso": "fora", "nota": "ainda não há mortos-vivos nem demônios"},
	"rito-de-purificacao": {"uso": "ativada", "alvo": "nenhum", "magia": true, "nota": "zona de alcance curto centrada em você, que anda junto"},
	"golpe-de-oportunidade": {"uso": "reacao", "nota": "ataque de oportunidade: o jogo pergunta quando um inimigo sai de um quadrado ao seu lado"},
	"provocar": {"uso": "ativada", "alvo": "inimigo_corpo", "nota": "usa o melhor entre Espírito e Irritar"},
	"castigo": {"uso": "reacao", "nota": "oferecida depois que um inimigo ao seu lado ataca um aliado"},
	"parede-de-escudos": {"uso": "passiva"},
	"escudo-agil": {"uso": "fora", "nota": "cobertura ainda não existe"},
	"avanco-combinado": {"uso": "fora", "nota": "ainda não programado"},
	"aguentem-recrutas": {"uso": "ativada", "alvo": "nenhum"},
	"instruir-armamento": {"uso": "fora", "nota": "cartas de arma ainda não existem"},
	"movimento-guiado": {"uso": "ao_virar"},
	"palavra-de-animo": {"uso": "na_mesa", "nota": "aparece como +1 quando um aliado a até 3 quadrados faz um teste"},
	"hino-de-coragem": {"uso": "fora", "nota": "ainda não programado"},
	"condenar": {"uso": "ativada", "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 3, "magia": true},
	"juizo": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 3, "magia": true, "exige_marca": true},
	"zona-da-penitencia": {"uso": "ativada", "alvo": "area", "magia": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"terra-do-louvor": {"uso": "ativada", "alvo": "area", "magia": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"teologia": {"uso": "passiva", "nota": "+1 no limite em testes de Religião (o símbolo na arma ainda não)"},
	"primeiros-socorros": {"uso": "ativada", "alvo": "aliado", "alcance": 1, "sem_si": true, "nota": "o aliado exila 1 do descarte e devolve 1 ao baralho"},
	"prece-rapida": {"uso": "fora", "nota": "ainda não programado"},
	"fe-inabalavel": {"uso": "ativada", "alvo": "nenhum", "nota": "vantagem em testes de Espírito e Sabedoria até o fim do turno"},
	"mao-angelical": {"uso": "ativada", "alvo": "aliado", "alcance": 1, "sem_si": true},
	"luz-da-verdade": {"uso": "ativada", "magia": true, "opcoes": [
		{"id": "iluminar", "nome": "Iluminar ao redor", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "nenhum"},
		{"id": "tirar-sombra", "nome": "Tirar a Sombra", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "qualquer_medio"}]},
	"ressurgir": {"uso": "ativada", "alvo": "aliado_caido", "alcance": 1, "magia": true, "nota": "alvo: aliado caído adjacente"},
	"intervencao-divina": {"uso": "fora", "nota": "ainda não programado"},
	"bencao-dos-salmos": {"uso": "ativada", "magia": true, "opcoes": [
		{"id": "resistencia", "nome": "Resistência 1", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "aliado", "alcance": 3},
		{"id": "curar", "nome": "Curar 3", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "aliado", "alcance": 3},
		{"id": "remover", "nome": "Remover uma ficha", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "aliado", "alcance": 1}]},
	"salmos-da-ira": {"uso": "ativada", "magia": true, "opcoes": [
		{"id": "dano", "nome": "2 de dano radiante", "custo": {"fadiga": 1, "acao": null}, "alvo": "inimigo_magico", "alcance": 3},
		{"id": "cegueira", "nome": "Cegueira", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "inimigo_magico", "alcance": 4},
		{"id": "cone", "nome": "Cone radiante", "custo": {"fadiga": 3, "acao": "padrao"}, "alvo": "area", "ataque_magico": true, "area": {"forma": "cone", "tamanho": 3}}]},
	"halo-do-conduite": {"uso": "ativada", "alvo": "area", "magia": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"halo-da-justica": {"uso": "ativada", "alvo": "area", "magia": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"salterio-de-cura": {"uso": "fora", "nota": "carta sem texto na planilha"},
	"grimorio-da-chama-sagrada": {"uso": "fora", "nota": "carta sem texto na planilha"},
	# Caçador
	"preparar-o-tiro": {"uso": "ativada", "alvo": "nenhum"},
	"tiro-certeiro": {"uso": "na_mesa", "nota": "durante o seu ataque à distância: descarte Mira, uma por vez"},
	"marca-do-cacador": {"uso": "ativada", "alvo": "inimigo_visivel"},
	"presa-ferida": {"uso": "passiva"},
	"flecha-aleijadora": {"uso": "ativada", "alvo": "inimigo_distancia"},
	"chuva-de-flechas": {"uso": "ativada", "alvo": "area", "area": {"forma": "aglomerado", "maximo": 3, "alcance": 4}},
	"rastrear": {"uso": "passiva", "nota": "num teste de Sobrevivência bem-sucedido, ganha 1 Foco"},
	"estudar-a-presa": {"uso": "fora", "nota": "ainda não programado (fraquezas por tipo de dano já existem nos inimigos)"},
	"armadilha-de-caca": {"uso": "ativada", "alvo": "area", "area": {"forma": "casa", "alcance": 1}},
	"oleos-e-iscas": {"uso": "ativada", "opcoes": [
		{"id": "oleo-1", "nome": "Óleo Inflamável (1 Fogo)", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "inimigo_magico", "alcance": 4},
		{"id": "oleo-2", "nome": "Óleo Inflamável (2 Fogo)", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "inimigo_magico", "alcance": 4},
		{"id": "oleo-3", "nome": "Óleo Inflamável (3 Fogo)", "custo": {"fadiga": 3, "acao": "padrao"}, "alvo": "inimigo_magico", "alcance": 4},
		{"id": "oleo-area", "nome": "Óleo Inflamável (área 2x2)", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "area", "area": {"forma": "quadrado", "tamanho": 2, "alcance": 4}},
		{"id": "isca", "nome": "Isca", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "area", "area": {"forma": "casa", "alcance": 8}},
		{"id": "antidoto", "nome": "Antídoto", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "aliado", "alcance": 1},
		{"id": "emplastro", "nome": "Emplastro", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "aliado", "alcance": 1}]},
	"flecha-envenenada": {"uso": "ativada", "alvo": "inimigo_distancia"},
	"flecha-de-rede": {"uso": "ativada", "alvo": "inimigo_distancia"},
	"funda-certeira": {"uso": "ativada", "alvo": "inimigo_distancia"},
	"pedra-atordoante": {"uso": "ativada", "alvo": "inimigo_distancia"},
	"cabra-da-montanha": {"uso": "fora", "nota": "ainda não programado"},
	"ponto-de-vantagem": {"uso": "fora", "nota": "altura ainda não existe"},
	"flecha-pesada": {"uso": "na_mesa", "nota": "durante o seu ataque, contra alvo imobilizado ou ferido"},
	"quebrar-a-fenda": {"uso": "na_mesa", "nota": "durante o seu ataque: Imobilizar ou Ferimento no defensor"},
	"camuflagem": {"uso": "ativada", "alvo": "nenhum"},
	"tiro-rapido": {"uso": "ativada", "alvo": "nenhum"},
	"faro-agucado": {"uso": "fora", "nota": "ocultação de inimigos ainda não existe"},
	"salto-de-recuo": {"uso": "ativada", "alvo": "nenhum"},
	"olho-de-aguia": {"uso": "fora", "nota": "ainda não programado"},
	"preparar-emboscada": {"uso": "ativada", "alvo": "nenhum"},
	"tiro-perfeito": {"uso": "ativada", "alvo": "inimigo_distancia", "exige_fichas": {"Mira": 3}},
	"olho-que-tudo-ve": {"uso": "passiva"},
	"predador-absoluto": {"uso": "fora", "nota": "ainda não programado"},
	"covil-do-arqueiro": {"uso": "ativada", "alvo": "area", "area": {"forma": "ao_redor", "tamanho": 3}},
	"tiro-mortal": {"uso": "ativada", "alvo": "inimigo_distancia", "exige_marca_ou_metade": true},
	"nada-escapa": {"uso": "fora", "nota": "ainda não programado"},
	# Mago
	"conjuracao-economica": {"uso": "passiva"},
	"tecer-com-maestria": {"uso": "fora", "nota": "ainda não programado"},
	"poder-de-combate": {"uso": "passiva"},
	"sobrecarga-arcana": {"uso": "ativada", "alvo": "nenhum"},
	"improviso-do-erudito": {"uso": "fora", "nota": "ainda não programado"},
	"de-volta-ao-basico": {"uso": "passiva"},
	"mao-magica": {"uso": "fora", "nota": "fora de combate"},
	"misseis-magicos": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 8, "magia": true, "misseis": 3},
	"contramagia": {"uso": "reacao", "nota": "oferecida quando um inimigo conjura (teste de Raciocínio contra o teste de Sabedoria do conjurador, com cartas)"},
	"armadura-arcana": {"uso": "ativada", "alvo": "aliado", "alcance": 1, "magia": true},
	"telepatia": {"uso": "fora", "nota": "fora de combate"},
	"detectar-magia": {"uso": "fora", "nota": "fora de combate"},
	"conjuracao-perfeita": {"uso": "passiva"},
	"reflexo-arcano": {"uso": "fora", "nota": "ainda não programado"},
	"mente-belica": {"uso": "ativada", "alvo": "nenhum"},
	"mana-densa": {"uso": "reacao", "nota": "oferecida quando uma magia inimiga tem você como alvo (descarta a carta de menor valor da mão)"},
	"mente-afiada": {"uso": "passiva"},
	"estrategia-arcana": {"uso": "passiva"},
	# Repertório (0.14): cada opção tem custo, alvo e efeito próprios (texto da carta).
	# O jogador escolhe a opção ao usar; Batalha._info_lado junta a opção ao registro.
	"aprendiz-de-fogo": {"uso": "ativada", "magia": true, "repertorio": true, "opcoes": [
		{"id": "chama-nenem", "nome": "Chama Neném", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4},
		{"id": "manipular-chama", "nome": "Manipular Chama", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "qualquer_adjacente"},
		{"id": "nuvem-de-brasas", "nome": "Nuvem de Brasas", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "area", "area": {"forma": "quadrado", "tamanho": 2, "alcance": 4}}]},
	"labareda-voraz": {"uso": "ativada", "alvo": "area", "magia": true, "ataque_magico": true, "area": {"forma": "linha", "comprimento": 4}},
	"aprendiz-de-agua": {"uso": "ativada", "magia": true, "repertorio": true, "opcoes": [
		{"id": "nado-avancado", "nome": "Nado Avançado", "custo": {"fadiga": 1, "acao": "movimento"}, "alvo": "nenhum", "motivo_se": "nado"},
		{"id": "lava-jato", "nome": "Lava Jato", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4},
		{"id": "chicote-de-agua", "nome": "Chicote de Água", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4}]},
	"onda": {"uso": "ativada", "alvo": "area", "magia": true, "ataque_magico": true, "area": {"forma": "adjacente", "tamanho": 3}},
	"aprendiz-de-terra": {"uso": "ativada", "magia": true, "repertorio": true, "opcoes": [
		{"id": "arma-petrea", "nome": "Arma Pétrea", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "nenhum"},
		{"id": "muro", "nome": "Muro", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "area", "area": {"forma": "adjacente", "largura": 2, "profundidade": 2}},
		{"id": "enterrar-na-fissura", "nome": "Enterrar na Fissura", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4}]},
	"missil-de-rocha": {"uso": "ativada", "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4, "magia": true},
	"aprendiz-de-ar": {"uso": "ativada", "magia": true, "repertorio": true, "opcoes": [
		{"id": "passo-leve", "nome": "Passo Leve", "custo": {"fadiga": 1, "acao": "movimento"}, "alvo": "nenhum", "motivo_se": "passo_leve"},
		{"id": "rajada", "nome": "Rajada", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4},
		{"id": "ventos-cortantes", "nome": "Ventos Cortantes", "custo": {"fadiga": 3, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4}]},
	"ciclone": {"uso": "ativada", "alvo": "area", "magia": true, "area": {"forma": "quadrado", "tamanho": 2, "alcance": 4}},
	"aprendiz-de-luz": {"uso": "ativada", "magia": true, "repertorio": true, "opcoes": [
		{"id": "lanterna-palida", "nome": "Lanterna Pálida", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "area", "area": {"forma": "quadrado", "tamanho": 1, "alcance": 4}},
		{"id": "clarao-revelador", "nome": "Clarão Revelador", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "nenhum"},
		{"id": "flecha-de-luz", "nome": "Flecha de Luz", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 4}]},
	"raio-radiante": {"uso": "ativada", "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 8, "magia": true, "nota": "o scry 3 ainda não"},
	"aprendiz-de-sombra": {"uso": "ativada", "magia": true, "repertorio": true, "opcoes": [
		{"id": "veu", "nome": "Véu", "custo": {"fadiga": 1, "acao": "movimento"}, "alvo": "nenhum", "motivo_se": "oculto"},
		{"id": "lamina-das-sombras", "nome": "Lâmina das Sombras", "custo": {"fadiga": 1, "acao": "padrao"}, "alvo": "inimigo_magico", "ataque_magico": true, "alcance": 1},
		{"id": "terror-abismal", "nome": "Terror Abismal", "custo": {"fadiga": 2, "acao": "padrao"}, "alvo": "nenhum"}]},
	"servo-sombrio": {"uso": "fora", "nota": "ainda não programado"},
	# Lado B das meias cartas (só um marcador)
	"meia-carta": {"uso": "passiva"},
}

## Metades de carta de herói programadas. "parcial" = parte dos efeitos depende
## de aliados ou de sistemas que ainda não existem.
const HEROIS := {
	"foco-mortal": {"parcial": false},
	"a-muralha": {"parcial": true, "nota": "a ativada (redirecionar dano de aliado) precisa de aliados"},
	"incansavel": {"parcial": true, "nota": "a passiva (penalidades de ambiente) ainda não tem uso"},
	"tomar-a-posicao": {"parcial": true, "nota": "a desencadeada precisa de aliados"},
	"ombro-a-ombro": {"parcial": true, "nota": "a passiva (+1 de resistência ao lado de um aliado) e o crítico funcionam"},
	"larapio": {"parcial": false},
	"impostor": {"parcial": true, "nota": "só a passiva (limite 23 em Mentira) funciona"},
	"estrela-do-amanhecer": {"parcial": true, "nota": "a desencadeada (fichas de inimigos) ainda não"},
	"o-martelo-da-luz": {"parcial": true, "nota": "funcionam a ativada (ficha de Vantagem na arma), a desencadeada e o crítico; a passiva e o tipo de dano dependem de devoção, que ainda não existe"},
	"folha-de-carvalho": {"parcial": true, "nota": "o Ferimento da ativada ainda não (só imobiliza)"},
	"predador-da-selva": {"parcial": true, "nota": "só a desencadeada (Preparo no início do turno) funciona"},
	"controlador-do-arcano": {"parcial": false},
	"mil-oficios": {"parcial": true, "nota": "funcionam a passiva (escolhas na criação) e o crítico (mostra as 4 cartas do topo)"},
	"o-atemporal": {"parcial": true, "nota": "a desencadeada (andar ao gastar Reação) ainda não"},
	"o-feerico": {"parcial": true, "nota": "quase nada funciona ainda (terreno difícil, rastros e magia de inimigos)"},
	"o-inabalavel": {"parcial": true, "nota": "funcionam a ativada e o crítico"},
	"palavra-de-aco": {"parcial": true, "nota": "a passiva (ignorar Imobilizar) ainda não"},
	"a-boa-estrela": {"parcial": false},
	"matador-de-gigante": {"parcial": false},
	"furia-crescente": {"parcial": false},
	"brado-da-horda": {"parcial": true, "nota": "a ativada (brado com ataques grátis) ainda não"},
	"o-oportunista": {"parcial": true, "nota": "a desencadeada e o crítico ainda não"},
	"sempre-uma-saida": {"parcial": false},
	"o-sobrevivente": {"parcial": true, "nota": "a desencadeada ainda não"},
	"trabalhador": {"parcial": true, "nota": "resistência a Concussão ainda não existe"},
	"conhecedor-do-terreno": {"parcial": false},
	"mestre-das-cavernas": {"parcial": true, "nota": "enxerga no escuro como penumbra; criar corda e tocha fica para a exploração"},
	"seguidor-da-chama": {"parcial": true, "nota": "a desencadeada (reações inimigas) ainda não"},
	"seguidor-da-noite": {"parcial": true, "nota": "a passiva e a ativada (descanso longo) ainda não"},
	"devorador-de-grimorios": {"nota": "passiva na criação (1 repertório Aprendiz custa 0 XP); ativada = 1 troca de arma por rodada como ação livre"},
}


static func lado_programado(slug: String) -> bool:
	return LADOS.has(slug)


static func carta_programada(carta: Dictionary) -> bool:
	for l in carta["lados"]:
		if l != null and not lado_programado(_slug(l["nome"])):
			return false
	return true


static func heroi_programado(heroi: Dictionary) -> bool:
	return HEROIS.has(_slug(heroi["nome"]))


static func nota_carta(carta: Dictionary) -> String:
	var notas := PackedStringArray()
	for l in carta["lados"]:
		if l == null:
			continue
		var s := _slug(l["nome"])
		if LADOS.has(s) and LADOS[s]["uso"] == "fora":
			notas.append("%s: sem efeito na batalha (%s)" % [l["nome"], LADOS[s].get("nota", "")])
		elif LADOS.has(s) and LADOS[s].has("nota"):
			notas.append("%s: %s" % [l["nome"], LADOS[s]["nota"]])
		elif not LADOS.has(s):
			notas.append("%s: ainda não programado" % l["nome"])
	return " · ".join(notas)


static func _slug(nome: String) -> String:
	return preload("res://core/catalogo.gd").slug(nome)
