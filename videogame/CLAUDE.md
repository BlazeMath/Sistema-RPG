# Notas para quem continua o desenvolvimento

Projeto do Lucas (designer e palavra final). O Claude programa. Tudo em português do Brasil.
Plano completo: doc "Sistema 21 — Plano de Desenvolvimento do Videogame" (artifact no claude.ai).

## Como trabalhar

- Godot 4.4, **GDScript** (o ambiente do Claude não tem .NET). Testado com Godot 4.4.1.
- Regras moram só em `core/` (GDScript puro, `RefCounted`, sem nós de cena). A apresentação nunca decide regra.
- Use `preload("res://...")` em vez de `class_name`: os testes rodam sem importar o projeto no editor.
- Aleatoriedade sempre por `RandomNumberGenerator` com semente (partidas reproduzíveis, base para rede e replay).
- Toda regra nova ganha teste em `tests/test_*.gd`. Rodar: `godot --headless --path . -s res://tests/run_tests.gd`.
- Cartas vêm da planilha oficial via `tools/exportar_cartas.py`. Não editar `data/cartas/*.json` à mão.
  O relatório aponta cartas novas/mudadas pela impressão digital.
- Regra ambígua vira pergunta para o Lucas, nunca suposição. Interpretações provisórias ficam listadas abaixo.
- O Lucas não usa terminal nem git: entregas vão em .zip, e ele envia ao GitHub pelo navegador.

## Regras decididas para o digital

- Baralho: 52 cartas comuns, sem efeitos. Não muda do início ao fim; evoluem habilidades e itens.
- Tudo em turnos, inclusive exploração. Não existe "fim de combate".
- Cena: começa quando a missão ou uma parte dela começa. Único momento de compra: 2 + Sabedoria.
- Descanso curto (pontos marcados, 2–3 numa missão longa): exila 1 do descarte, devolve até 10 do descarte. Não tira fadiga.
  Só sem inimigos por perto; o ponto de descanso é também onde se salva no meio da missão (Lucas, 21/10/2026).
- Descanso longo (acampamento ou taverna): recompõe tudo.
- Baralho vazio = inconsciente. Dano em inconsciente: descarte → exílio. Perder todo o descarte = morte.
- Inimigos só atacam caídos se não houver outra ação possível contra os demais.
- Derrota (modo normal): todos caídos ou um morto. Morte permanente: só modo opcional.
- Distâncias: curto até 4 quadrados, médio 5–8, longo 9–12, além disso sem ataque.
- Iniciativa: simulada e oculta, no início da cena, com baralho à parte (não gasta vida): 2 cartas + Destreza + Iniciativa.
- Testes sempre manuais (ataque, defesa, perícia).
- 3 a 6 personagens; solo e local primeiro (online bem depois, pedido do Lucas). Combates montados à mão; vida e dano dos monstros sobem com o nível.

## Confirmadas pelo Lucas (20/10/2026)

- Cartas usadas em testes, ataques e defesas vão para o descarte. Cada personagem tem baralho, descarte e exílio próprios.
- A carta exilada (cura, descanso curto) é sempre a mais recente do descarte. Cartas curadas vão para o fundo do baralho.
- Nova cena: a mão antiga é embaralhada no baralho e o personagem compra a mão nova (2 + Sabedoria).
- Ás: o jogo escolhe 1 ou 11 sozinho, pela soma.
- Iniciativa simulada: só 2 cartas + Destreza + Iniciativa, sem estouro.

## Confirmadas pelo Lucas (20/10/2026, depois da 0.9)

- **Sem momentum**: a regra foi abandonada no playtest. Não implementar.
- Testes de movimento (nadar, escalar, saltar, amortecer queda) seguem as tabelas do livro, não a escala por nível.
- Kit Médico: tira todo o Sangramento e cura 2.
- Focos: valores da 0.9 valem por enquanto; no futuro cada item terá números próprios (ex.: varinha de batalha com mais dano,
  cajado de viajante com menos dano e mais limite de fadiga).
- Limites corrigidos (Flecha de Rede 2, Mestre das Cavernas 3) ficam em Catalogo.CORRECOES até a planilha ser reexportada.

## Confirmadas pelo Lucas (21/10/2026)

- Áreas: o jogador escolhe o centro (ou só a direção, se parte dele), gira formas não simétricas; prévia na tela.
  Linhas param em paredes e atravessam personagens; 8 direções. Ataque em área: um teste contra a defesa de cada alvo;
  acerta aliados, salvo se a carta disser o contrário. Altura ignorada por enquanto.
- Zonas: sem "até o fim da cena" duram 10 rodadas; sustentar = pagar no início do turno do dono (perguntar);
  iguais sobrepostas não somam, diferentes somam; zona de magia some se o conjurador cair, a de item fica.
  Objetos criados bloqueiam visão; Bomba de Fumaça = cobertura parcial. Terreno difícil custa 2.
- Cobertura parcial = como uma faixa fora da distância; total = não pode ser atingido.
- Distância: 1 faixa fora → só 2 cartas (sem puxar, pode jogar da mão); 2 faixas → 1 carta.
- Empurrão: em linha reta para longe; para fora da área = em relação ao centro; colisão 2 de dano por quadrado que
  faltou, nos dois; armadura e escudo seguram. Desarmado: diferença + Força se ≥3. Diplomacia 5: inconsciente exila metade.
- Sombra: gasta quando o inimigo escolhe o alvo (IA decide o alvo no início do turno). Todos gastarem = ninguém gastou.
- Combates (filosofia): obstáculo (5–10 lacaios para 4; lacaio cai com 1,5 ataques e causa 10%), simples (lacaios = heróis,
  médios = heróis; médio cai com 3 ataques e causa 20%), complexo (2–3 das 8 ações vão para a missão), elite (sozinho:
  16 ataques, 40%, 2 heróis por turno; escoltado: 10 ataques, 25%; sem estratégia perde 60%), chefe (32–40 ataques;
  sem estratégia perde 90%, mediana 50%, boa 30%). Papéis: aggro, tank, control, support.
- Foco do digital: modo local. Perícias cortadas: Fortitude, Reflexos, Contatos.

## Estado

- Marco 0 (fundação): estrutura, exportador, núcleo de baralho/teste/combate/iniciativa, testes. ✔
- Versão de teste 0.2: duelo 1 contra 1 jogável (core/duelo.gd + ui/duelo_tela.gd), IA por critério de parada,
  executável de Windows. Valores provisórios em core/dados_duelo.gd (goblin vida 45: ~79% de vitórias na simulação).
- O Lucas pediu versões testáveis frequentes: cada entrega leva o .exe (zip separado; não vai ao GitHub, passa de 25 MB).
- 0.3: monte do baralho clicável na mesa para puxar (ui/monte_visual.gd), além de Espaço e botão.
- Renderer: gl_compatibility. Fontes DejaVu em assets/fontes (licença junto).
- 0.4: batalha no grid isométrico (core/grade.gd, core/unidade.gd, core/batalha.gd, ui/batalha_tela.gd), menu inicial
  (ui/main.tscn). Mundo 3D com câmera ortográfica isométrica e formas simples. Goblins: 2 Covardes (vida 12) e 1
  Atirador (vida 8, ideal curto/médio). Simulação com herói ingênuo: ~53% de vitórias.
- Provisório no grid (confirmar com o Lucas): 8 direções, diagonal custa 1, sem cortar canto de obstáculo,
  distância = maior diferença de colunas/linhas, linha de visão bloqueada por obstáculos.
- Reação ainda não tem uso (chega com as habilidades). Ataque de oportunidade, momentum, fadiga: 0.5/0.6.
- Atenção na UI: toda corrotina de animação confere `_geracao` (nova batalha durante animação travava o Godot).
- 0.5: regra nova dos testes (só cartas; atributo entra no dano), criação de heróis com salvamento (ui/criacao.gd,
  core/personagem.gd, user://herois.json), itens comuns (core/itens.gd), cartas em jogo com fadiga/virar/fichas
  (core/carta_em_jogo.gd, core/efeitos.gd, efeitos em core/batalha.gd), IA nível 2 (chance de estouro + cartas à vista),
  X1 contra Chefe Goblin e arena. Decisões provisórias em DECISOES_0.5.md (revisar com o Lucas).
- Para programar uma carta nova: registre o slug do lado em core/efeitos.gd e o efeito em batalha.gd
  (heroi_usar_carta / passivas nos cálculos / _virar / _critico).
- 0.6: dano no herói distribuído pelo jogador (Fase DISTRIBUINDO_DANO; `distribuicao_automatica` = true nos testes,
  a tela desliga), interações no mapa com testes de atributo e faixas (Fases INTERACAO_TESTE/INTERACAO_RESOLVIDA;
  dados em core/dados_exploracao.gd), inventário (Kit Inicial para todos, consumíveis repetidos = quantidade),
  inimigos desatentos (`alerta`, `vigia`). Decisões em DECISOES_0.6.md.
- 0.7: perícias na ficha (Personagem.PERICIAS, 4×3, 6×2, 8×1; tela em ui/criacao.gd) somadas ao atributo nos testes;
  queda = efeito "queda" com quadrados (dano 3 × (n − 1); n > 2 oferece Acrobacia, dificuldade 15 + n, para metade).
  Decisões em DECISOES_0.7.md.
- 0.8: dificuldade = valor alvo (atingir basta; "dificuldade" vira faixas em Batalha._normalizar_teste); testes com
  {"somar": [atributos/perícias]}; "abordagens" = jeitos de fazer a mesma ação. Grupo de até 4 (Sessao.grupo,
  user://grupo.json; ids "heroi", "heroi2"...), vida dos inimigos escala (Dados.escalar). Classes Ladino, Clérigo,
  Caçador e Mago: efeitos em core/cartas_classes.gd, registro em core/efeitos.gd; ataque mágico (ctx "magico");
  fichas nos inimigos (Sangramento, Veneno, Fogo, Ferimento, Cegueira...). Missão da fazenda em core/dados_fazenda.gd
  (mapa 30×20, câmera segue a unidade da vez). Inimigos têm "grupo" para alertas. Decisões em DECISOES_0.8.md.
- 0.9: raças e backgrounds (core/cartas_origens.gd, ganchos em batalha.gd; escolhas da criação em Personagem.ESCOLHAS).
  Sangramento/Veneno/Fogo persistentes (CartaEmJogo.PERSISTENTES; Fogo espalha e queima objetos em Batalha.chamas).
  Escala de dificuldade por nível (Batalha.NIVEIS + 3 por componente; dados usam "nivel"). Focos (Itens.FOCOS) no dano
  mágico. Testes sintéticos (teste_de_acao), refazer teste (resultado "pendente"), ataque de oportunidade
  (_percorrer/movimento_pendente), Castigo, Provocar. Decisões em DECISOES_0.9.md.
- 0.10: fichas pelo glossário do Lucas (Ferimento/Medo/Penalidade ficam até virar; Imobilizar −1 mov/ficha; Cegueira;
  Confusão com alvo sorteado; inimigo gasta Padrão para tirar ficha; Teste21.vantagem_automatica para inimigos), estado
  Caído (efeitos["caido"], derrubar(), heroi_levantar()), atributos 3/5 da tabela (só heróis), distância por faixas
  (Teste21 iniciais/sem_puxar), cobertura parcial (COBERTURA_PARCIAL), dano de empurrão, reações de inimigos
  (Unidade.reacoes), Sombra ao ser escolhido (Fase.SOMBRA_ESCOLHA), ações de vários turnos (custo "turnos", Fase.ACAO_LONGA),
  arremessáveis no chão (armas_no_chao), Besta Pesada, escala de inimigos base 4 (±30%, lacaios ±1 a cada 2).
  Simulação de balanceamento: tools/simular_balanceamento.gd (SIM_N, SIM_SAIDA). Decisões em DECISOES_0.10.md.
- 0.11: perícias cortadas (Fortitude, Reflexos, Contatos; migração em Personagem._migrar_pericias), focos do PDF como
  cartas de item (Itens.FOCOS com "cartas"/"limite"; arcano Mago, sagrado Clérigo), áreas e zonas (core/areas.gd formas;
  Batalha: spec_area, heroi_usar_area, _ataque_em_area com area_fila, criar_zona/zonas_em, sustentar, Fase.PERGUNTA,
  terreno difícil em Grade.custo_extra, Grade.visao_bloqueada), IA evita zona (Unidade.inteligencia), encontros pela
  filosofia do Lucas (core/encontros.gd: patamares, papéis, composição, calibragem medida na simulação; Dados.inimigo_de,
  Dados.encontro_na_arena). Decisões em DECISOES_0.11.md.
- 0.12: névoa de guerra (Batalha.visao_dos_herois, explorado, unidade_visivel, nome_visto; tela: _desenhar_nevoa).
  Decisões em DECISOES_0.12.md.
- 0.13: balanceamento — dano de referência 7 (Encontros.DANO_ATAQUE_HEROI), aggro +1 vel (corpo a corpo) ou +1 limite (distância), armas leves e focos +1, combate simples com lacaio/médio ×0,5 de vida (Encontros.calibragem_combate), custo de fadiga das cartas de repertório (efeitos 'custo'). Decisões em DECISOES_0.13.md.
- 0.14: cartas 'como parte de um ataque' na mesa (Batalha.cartas_durante_ataque / heroi_durante_ataque); repertório com 'opcoes' em core/efeitos.gd (CartaEmJogo.opcao; Batalha._info_lado junta a opção; usar_repertorio / usar_opcao); Areas forma 'cone'; Grade.bloqueio_extra (Muro) e modo de andar (nado, passo leve); perguntar_escolhas (a tela liga); heroi_usar_misseis. Decisões em DECISOES_0.14.md.
- 0.15: Conjuração (tag da planilha = símbolo do PDF: fadiga paga em outras cartas; Batalha.pagar_fadiga/pode_pagar_fadiga);
  luz e escuro (Batalha.escuro, fontes_de_luz/mapa_de_luz/nivel_de_luz, ve_de, enxerga_no_escuro, heroi_luz, LUZES; tela:
  camadas penumbra/breu em _desenhar_nevoa); devoções (core/devocoes.gd; Unidade.divindade/categoria/fraquezas/resiste_tipo;
  Batalha.tipos_de_dano/_bonus_por_tipo); cripta de Pedravelha (core/dados_masmorra.gd: piso pedra, paredes em MultiMesh);
  campanha e vila (core/campanha.gd, ui/vila.gd; Sessao.campanha); simulação com IA de habilidades e horda
  (tools/simular_balanceamento.gd, SIM_IA, SIM_HORDA). Decisões em DECISOES_0.15.md.
- 0.16: fadiga escolhida (Batalha.fadiga_escolhida/sobra_de_fadiga/cartas_para_fadiga; tela _abrir_fadiga); escuro = 1 carta;
  campanha guarda só o exílio; ficha de Foco = scry 1 (heroi_usar_foco, scry/_scry_decidir); heroi_virar(i, "acao"|"preparo");
  Planejar 2 cartas; mãos (maos_de) e segunda arma (Unidade.arma_reserva, ficha "arma2", heroi_trocar_arma, custo_troca);
  cartas desenhadas como cartas (_carta_ui) e abas Cartas/Registro; heróis prontos (core/herois_prontos.gd) e grupo no menu;
  música (autoload Musica em ui/musica.gd; faixas de tools/gerar_musica.py em assets/musica). Decisões em DECISOES_0.16.md.
- 0.17: inimigos que conjuram (Unidade.magias; Batalha._ia_conjurar, opcoes_de_anular, _anular, _executar_magia_inimiga;
  pergunta "anular": Mana Densa e Contramagia); Unidade.flutua (fantasmas); ao_acertar com "max"; cenário com "luz_ambiente"
  e "zonas"; missão do pântano (core/dados_pantano.gd). Decisões em DECISOES_0.17.md.
- 0.18: modelos 3D KayKit (CC0, assets/modelos + CREDITOS.txt; ui/modelos.gd: TIPOS unidade->modelo/armas/cor/escala,
  animações Idle/Walking_A/ataque/Hit_A/Death_A ligadas em _tocar_eventos; OBJETOS obstáculo->modelo, chave "tipo@piso";
  casas de várias casas viram um modelo só em _construcoes_em_bloco; enfeites da cripta em _enfeitar_cantos); menu de
  pausa (ui/menu_pausa.gd, Esc na batalha e na vila; tela cheia em user://config.json); jogos salvos (core/salvamento.gd,
  3 espaços em user://saves; ui/janela_saves.gd; salvar só na vila, carregar no menu e na vila). Decisões em DECISOES_0.18.md.
- 0.19: troca de arma 1 Padrão (grande 2; Bandoleira 2/cena, 1/turno); reações dos heróis sempre perguntadas (pergunta
  "reacao" para Cascavel/Castigo via _oferecer_reacao; "oportunidade" para Golpe de Oportunidade, oportunidade_recusada);
  Contramagia contra valor_resistido do conjurador; Muro com vida (dano_no_muro, muro_em; IA _muro_no_caminho/_ia_quebrar_muro;
  empurrão bate no muro); névoa em degradê (textura 1 px/quadrado numa tampa a ALTURA_NEVOA, deslocada para a câmera) e
  luz dinâmica (_atualizar_luzes: OmniLight3D por fonte; chão e paredes em pedaços 8×8 pelo limite de 8 luzes por objeto);
  pontos de descanso (interação "descanso"; opção "sem_inimigos_perto"; Exploracao.ponto_de_descanso; Batalha.motivo_salvar,
  descansos_usados) e salvar no meio da missão (core/instantaneo.gd: retrato da Batalha em var_to_str, objetos com
  referência; Salvamento "missao"; Sessao.estado_salvo; nova_batalha restaura); campanha em ciclos (Campanha.CICLOS,
  "requer", motivo_trancada, nível do grupo e XP_POR_NIVEL, inimigos +25% vida/+1 dano por nível, efeito "desbloquear");
  cenário interativo (Exploracao.arvore_frutifera, pedra_alta — obstáculo "pedra_alta", Batalha.no_alto dá vantagem —,
  movel_com_itens, estante_lore — efeito "lore"). Decisões em DECISOES_0.19.md.
- 0.20: tela de fim de turno (Batalha.opcoes_fim_de_turno/fim_de_turno_tem_escolha; encerrar_turno(escolhas) com
  "fadiga", "respirar", "opcionais"; Bênção Persistente uso "fim_turno" em _bencao_persistente); fila de perguntas
  (perguntas_na_fila); Estrela do Amanhecer pergunta aliado e carta; fichas de herói 1 por tipo por carta
  (CartaEmJogo.pode_receber, EMPILHAVEIS = Fúria; Unidade.fichas_a_escolher → tela pergunta; Batalha.mover_ficha);
  Preparo vira só a sua carta; Mira descartável em qualquer ataque (slug "mira" em cartas_durante_ataque; Tiro Certeiro
  soma +2); Foco entre a carta aberta e a fechada (Teste21.fechada_pendente/receber_fechada; Batalha._adiar_fechada,
  heroi_foco_no_teste, heroi_receber_fechada); Foco Mortal só em cartas tipo "arma", mínimo 1; hero cards com "opcoes"
  (Folha de Carvalho); Larápio pergunta no dano em área (larapio_pendente, _dano_no_heroi_agora); Devorador de Grimórios
  (Personagem._repertorio_gratis, troca livre por rodada); nota_da_carta (Avalanche); Cota de Malha limitada à vida;
  casas_para_atacar/destino_escolhido (Ombro de Ferro); heróis atravessam aliados (modo "aliados" em Grade.alcance,
  "passa"; Batalha._sem_passagem); heroi_em_combate bloqueia descanso; XP +1/nível; lacaio 11 de vida
  (Encontros.VIDA_LACAIO), chefe ×0,52; câmera não segue inimigo invisível; WASD contínuo em _process; música sem
  sobrepor (Musica._tocador_atual); barra de vida em partes. Decisões em DECISOES_0.20.md.
- 0.21: interface nova em ui/batalha_tela.gd (_montar_hud: topo fino, _painel_ini com a iniciativa, barra _baixo;
  menus flutuantes _menus_flutuantes/_fixar/_atualizar_menus_flutuantes para Habilidades/Ações/Registro; mão em leque
  _arrumar_leque; mesa compacta acima da barra); fichas _abrir_ficha_do_heroi/_abrir_ficha_do_monstro (botão direito;
  Batalha.descobertas guarda fraquezas/resistências reveladas); carta de arma (CartaEmJogo tipo "arma", slug "arma",
  Personagem.cartas_em_jogo_cfg; virar = heroi_trocar_arma; Itens.descricao_arma); inventário com _retrato_3d e mãos;
  Personagem.EFEITOS_ATRIBUTO/texto_atributo (criação com ⓘ e ficha); brilho de carta (Batalha._log emite "brilho"
  quando a mensagem começa com o nome de uma carta de herói); efeitos _efeito_cura/_efeito_raio; sons _som com
  assets/sons de tools/gerar_sons.py. Decisões em DECISOES_0.21.md.
- 0.22: reações dos monstros estilo Descent (core/reacoes_monstros.gd POR_NOME, aplicada em Dados.inimigo_de;
  gatilhos ao_ser_atacado/ao_atacar/ao_morrer; "livre" = 1 vez por rodada sem gastar Reação; Batalha._efeito_reacao_monstro:
  investir, inspirar (efeito "inspirado" em _bonus_de_dano), chamar, mover, estilhacar, fichas_ao_lado, remontar →
  _remontar_mortos no início da rodada, evento "reviver"); planos (Batalha.plano_do_inimigo, _atualizar_plano com
  Unidade.estrategia/intencao/alvo_plano, evento "estrategia"; _anunciar_intencoes quando a vez passa de monstro para
  herói, evento "intencoes"); _ia_limpar_com_movimento (monstro que não precisa andar tira 1 ficha com o Movimento);
  ações do livro: heroi_correr/heroi_saltar (teste_de_acao com efeitos "correr"/"saltar"; efeitos "correu" = vantagem
  contra, "saltando" = ignora terreno e AdO com vantagem, "cai_ao_parar" → _fim_da_corrida), manobras
  (Batalha.MANOBRAS, heroi_manobra: Luta+Força contra valor_resistido(Força); efeito "manobra"; "manobra_limite" −5 por
  tamanho; agarrar = efeito "agarrado" → passos_por_acao 0, _ia_escapar); tutorial (core/dados_tutorial.gd, cenário
  "tutorial" com etapas; Batalha.tutorial/tutorial_etapa/tutorial_flags, _tut(flag), avancar_tutorial só na vez do
  herói, tutorial_proximo; inerte(u) = boneco). Decisões em DECISOES_0.22.md.
- Para criar um cenário de exploração: copie o formato de core/dados_exploracao.gd (interações são só dados;
  efeitos novos entram em Batalha._aplicar_efeito).
- Plano de versões antigo: 0.5 cartas de habilidade do Guerreiro (fadiga, virar carta, Foco, Guarda) · 0.6 grupo de 3 heróis
  (Guerreiro, Ladino, Clérigo), armadura com vida própria, ataque de oportunidade · depois a missão da fazenda.
- 0.23: vila andável (core/dados_vila.gd, modo "vila", exploracao_livre: deslocamento 30 sem inimigos; efeito
  "abrir_vila" abre ui/vila.gd por cima com `aba` = missoes/mercado/ferreiro/estalagem; Campanha.comprar_equip/vender);
  catacumbas (core/dados_catacumbas.gd: 11 salas, níveis Grade.niveis/escadas — vizinhos só trocam de nível por escada;
  _mundo usa ALTURA_NIVEL; beirada = interação com queda); cenas (Batalha: gatilhos/_casa_do_heroi, _narrar → evento
  "narrativa", grupos → _verificar_avistamentos alerta o grupo ao ser visto, armadilhas/_disparar_armadilha/_revelar_armadilha,
  _procurar e heroi_procurar, combates_vencidos + opção "requer_combates", opções "requer_carta"/"requer_classe"/"alcance");
  levantar caído (heroi_levantar_aliado, dificuldade_de_levantar 17–25, curas +1 no limite a cada 2, efeito "levantar_aliado");
  chefes (Unidade.habilidades → _ia_habilidades: marcar_area, ovo, teleporte, cavar, muralha, defensivo; protegido_por;
  escolta → _ia_escolta); intenção narrativa por monstro no fim do turno dele (_anunciar_intencao, DICAS, evento "intencao");
  cartas que faltavam em core/cartas_extras.gd (LADOS, motivo, usar via Origens.usar, ao_virar, depois_do_ataque).
  Decisões em DECISOES_0.23.md.
