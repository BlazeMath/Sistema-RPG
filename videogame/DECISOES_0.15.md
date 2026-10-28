# Versão 0.15 — escuro e luz, devoções, a cripta, a vila e a simulação com habilidades

Ladino e Clérigo ficaram como estavam, como você pediu.

## O símbolo de Conjuração (fadiga em outras cartas)
1. No PDF, as cartas com o símbolo (as cartas com uma gota) são exatamente as que têm a tag "Conjuração" na planilha. O jogo usa essa tag.
   - Valem as magias de Mago e Clérigo: os Aprendizes, Labareda, Onda, Ciclone, Mísseis, Armadura Arcana, Toque Restaurador, Feixe de Luz, as zonas e outras.
2. **Como paga**:
   - Primeiro na própria carta.
   - O que não couber vai para as outras cartas do herói, com a de mais espaço livre primeiro; a carta de herói e a do foco também contam.
   - O registro mostra para onde foi cada fadiga.
   - **Você não escolhe a carta** (fica para depois, se quiser).
3. Por isso o **Ventos Cortantes** (3 de fadiga no Aprendiz de Ar, de limite 2) agora funciona. A Armadura Arcana (2 numa carta de limite 2) também pode usar o espaço das outras.
4. As zonas sustentadas (Penitência, Louvor) também pagam o sustento com outras cartas.
5. **Custos do Mago**: conferi o PDF carta por carta. Os custos e limites batem com o que o jogo já usava. O que faltava era só essa regra de Conjuração.

## Escuro e luz
6. **Três níveis**:

   | Nível | Como fica |
   | --- | --- |
   | Claro | Enxerga normalmente. |
   | Penumbra | Enxerga, mas quem está lá tem cobertura parcial contra ataques de longe. |
   | Escuro | Não enxerga, a não ser ao lado. |

   - Missões ao ar livre continuam claras.
   - A cripta é escura.
7. **Fontes de luz** (claro / penumbra, em quadrados; todas precisam de linha de visão):

   | Fonte | Claro | Penumbra |
   | --- | --- | --- |
   | Tocha (texto do PDF) | 4 | 8 |
   | Lanterna (PDF) | 4 | — |
   | Fogueira ou braseiro | 3 | 6 |
   | Tocha de parede | 3 | 6 |
   | Objeto em chamas | 2 | 4 |
   | Criatura com ficha de Fogo | 1 | 2 |
   | Lanterna Pálida | 4 | — |
   | Lanterna da Fé | 4 | — |
   | Luz da Verdade | o seu Espírito | — |

   Os números das fogueiras, das chamas e do Fogo são meus.
8. **Regras no escuro** (minhas):
   - Atacar quem você não enxerga: só corpo a corpo, com desvantagem (2 cartas).
   - Ataques à distância e magias de alvo precisam enxergar o alvo.
   - Quem tem visão no escuro enxerga o escuro como penumbra. Na ficha: Visão Élfica, Filho da Pedra e Mestre das Cavernas. Entre os inimigos: goblins, Toupeira e mortos-vivos.
   - Quem carrega luz fica visível de longe, inclusive para os inimigos.
9. **Acender**:
   - Tocha: ação Padrão, gasta 1 tocha dos consumíveis e precisa de uma mão livre. Quem segura a tocha defende com as cartas reveladas (texto do PDF).
   - Lanterna: ação de movimento, presa ao cinto, não ocupa as mãos. A planilha dizia "com as mãos livres"; o alcance curto é o do PDF.
   - Mãos ocupadas:
     - Arma: 1 mão; 2 se for de duas mãos ou grande.
     - Escudo: 1 mão.
     - Foco: as mãos do foco.
   - Guerreiro com espada e escudo não segura tocha.
   - Apagar é livre.
10. **Cartas que agora funcionam**:
    - Lanterna Pálida: aponta um ponto a até 4; fica até o fim da cena.
    - Lanterna da Fé: a luz sai ao redor de você. O cone ainda não. Precisa de uma mão livre.
    - Luz da Verdade: as duas opções.
    - Clarão Revelador e Véu (já funcionavam).
11. **Na tela**: a penumbra fica azulada, e o que você só vê com visão no escuro fica mais escuro ainda. Aparecem os botões "Acender tocha" e "Acender lanterna" quando o lugar é escuro.

## Devoções
12. Criei 4 divindades genéricas. O Clérigo escolhe uma na criação, e ela define a devoção:

    | Divindade | Devoção | Tipo de dano | Inimigos da devoção |
    | --- | --- | --- | --- |
    | Solenne, a Aurora | Luz | Radiante | mortos-vivos e demônios |
    | Karrak, o Martelo | Guerra | Trovão | goblinoides |
    | Verdana, a Mãe Verde | Natureza | Natural | mortos-vivos e aberrações |
    | Ossário, o Guardião dos Mortos | Morte | Necrótico | mortos-vivos |

    Clérigos salvos sem divindade ficam com Solenne.
13. **O Martelo da Luz** agora funciona inteiro:
    - Passiva: +3 de dano contra inimigos da devoção.
    - Ativada: a arma ganha o tipo de dano da devoção, além da ficha de Vantagem.
14. **Tipos de dano**:
    - Os inimigos agora têm categoria (goblinoide, fera, morto-vivo...), fraquezas e resistências por tipo de dano.
    - Fraqueza soma ao dano; resistência ao tipo subtrai.
    - Com mais de um tipo no ataque, vale o melhor para o atacante: a resistência só conta se todos os tipos forem resistidos.
    - O tipo vem da arma.
    - Nas magias, vem das tags da carta: Radiante/Luz = Radiante, Fogo = Fogo, Terra = Concussão.
    - Magia divina sem tipo usa o da devoção; magia arcana sem tipo é Arcano.
15. **Cartas contra mortos-vivos e demônios** que agora funcionam:
    - Feixe de Luz (+2), Palavra de Banimento (ignora resistência), Raio Radiante (+Sabedoria), cone dos Salmos da Ira (dobra).
    - Água Benta (as duas opções), Círculo de Proteção (você e aliados a até 4).
    - Expulsar: teste de Espírito automático contra o do inimigo. Ele é empurrado 2 e não se aproxima de você até o seu próximo turno.
    - Rito de Purificação: zona de raio 4 que anda com você; sustentar custa 1.
    - Golpe da Punição: o dano é Radiante além do da arma, e o alvo não se cura até o seu próximo turno.

## A cripta de Pedravelha (masmorra)
16. **História**:
    - Os mortos da cripta sob a capela velha estão se levantando, e goblins saqueiam as tumbas.
    - No fundo está Sir Aldric, um cavaleiro enterrado com a espada.
    - Mapa 40×24, escuro.
17. **Ordem pela sua filosofia**:
    - **Ossário**: obstáculo; esqueletos lacaios (7 para 4 heróis, alguns arqueiros) que estão deitados e levantam quando alguém chega perto.
    - **Salão dos goblins**: combate simples, com a fogueira acesa.
    - **Capela**: descanso curto na fonte, e um altar que dá Preparo a quem passar no teste.
    - **Porta trancada**: fechadura (Ladinagem) ou arrombar (Atletismo + Força). Arrombar acorda a cripta.
    - **Cripta**: chefe Sir Aldric com a guarda de ossos (médios). Braseiros iluminam só a frente da sala.
    - Ao sul fica a câmara do tesouro, com uma armadilha no corredor.
18. **Esqueletos**:
    - Fracos contra Concussão (+2) e Radiante (+2); resistem a Perfuração (−2).
    - Sir Aldric: Radiante +3; resiste a Perfuração (−2). Na primeira simulação, com papel tank e resistência a Corte, ele ficou difícil demais (1% de vitórias sem estratégia); agora é chefe neutro.
    - Os números são meus.
19. **Luz na missão**:
    - Os heróis entram com as lanternas do kit apagadas.
    - Na entrada, os suportes dão 2 tochas por herói.
20. **Ouro**: contrato de 120; dá para achar mais 80 em ouro nos baús e no sarcófago.

## A vila (guilda)
21. Novo botão no menu: **Vila de Pedravelha**. São três quadros:
    - **Quadro de missões**: fazenda (80), cripta (120), arena de treino (0). Ao partir daqui, a missão vale de verdade: não dá para recomeçar.
    - **Mercado**: compra consumíveis com ouro para um herói do grupo. Os preços são meus; o PDF não tem preços:

      | Item | Preço |
      | --- | --- |
      | Tocha | 1 |
      | Ração | 2 |
      | Antídoto | 8 |
      | Kit Médico | 10 |
      | Poções | 12 |
      | Veneno Ácido | 12 |
      | Bomba de Fumaça | 15 |
      | Frasco de Piche | 15 |
      | Os outros | 10 |

    - **Estalagem**: descanso longo, 5 de ouro por herói.
22. **Entre missões**:
    - O exílio e o descarte do fim da missão continuam na próxima, até o descanso longo.
    - Os consumíveis gastos somem da ficha, e os achados entram nela.
    - O grupo começa com 60 de ouro.
    - Na criação, você continua podendo pôr qualquer quantidade de itens, para testar.
23. Sair pelo menu no meio de uma missão da vila não registra nada: nem ouro, nem feridas.

## Simulação (200 combates por linha; completa em Balanceamento_0.15.csv)
24. **Duas IAs de herói**:
    - **Ingênua** (a de antes): anda até o inimigo mais próximo e ataca.
    - **Com habilidades** (nova):
      - O Clérigo cura quem tem 5 ou mais cartas no descarte (Toque Restaurador, Bênção dos Salmos).
      - Com o baralho abaixo da metade, 6 ou mais no descarte e sem inimigo ao lado, o herói usa Recuperar o Fôlego.
      - Usa as cartas de ataque antes das outras e as cartas "durante o ataque" na mesa.
      - Usa áreas que pegam 2 ou mais inimigos sem pegar aliados.
    - **Cartas por classe na IA com habilidades**:

      | Classe | Cartas |
      | --- | --- |
      | Guerreiro | Ombro de Ferro, Postura do Leão |
      | Ladino | Ataque Furtivo, Nunca Visto |
      | Clérigo | Feixe de Luz, Toque Restaurador, Bênção dos Salmos |
      | Caçador | Flecha Aleijadora, Flecha Pesada |
      | Mago | Aprendiz de Fogo, Aprendiz de Terra, Mísseis + Armadura Arcana |

    - Por turno, cada herói usa em média 1 carta, cura 0,36 vez, usa Recuperar o Fôlego 0,04 vez e usa 0,2 carta na mesa.

25. **Vitórias** (4 heróis / 2 heróis):

    | Combate | Ingênua | Com habilidades | Sua meta |
    | --- | --- | --- | --- |
    | Simples | 99% / 93% | 100% / 97% | — |
    | Elite sozinho | 43% / 30% | 68% / 43% | sem estratégia ~40%; boa ~75% |
    | Elite com escolta | 51% / 29% | 60% / 39% | idem |
    | Chefe | 14% / 6% | 56% / 26% | sem estratégia ~10%; mediana ~50% |
    | Toupeira Atroz | 48% / 31% | 72% / 46% | elite |
    | Sir Aldric e a guarda | 13% / 9% | 39% / 21% | chefe |

    - Com habilidades, o grupo fica perto do que você chamou de jogar com estratégia: elite com 68% (meta 75%), chefe com 56% (meta 50%).
    - Combate simples com habilidades: sobra 71% da vida do grupo (gasta 29%) em vez de 55%. As curas e o fôlego seguram o baralho.
    - A simulação de Sir Aldric é numa arena clara, sem a exploração e sem o escuro.

26. **Dano por turno no boneco de treino** (ingênua → com habilidades):

    | Classe | Ingênua | Com habilidades |
    | --- | --- | --- |
    | Guerreiro | 11,8 | 16,8 |
    | Caçador | 10,0 | 11,2 |
    | Ladino | 8,1 | 9,2 |
    | Clérigo | 7,9 | 6,2 |
    | Mago | 9,8 | 5,6 |

    - O Clérigo cai porque gasta ações curando.
    - O Mago cai porque o boneco fica a 5 quadrados, fora do alcance da Chama Neném: a IA usa os Mísseis (3 garantidos) em vez de andar. Nos combates, o Mago com habilidades faz 7,9 por turno.

27. **Horda** (4 heróis; começam 6 lacaios e entram 2 por rodada, no máximo 12 vivos):

    | | Ingênua | Com habilidades |
    | --- | --- | --- |
    | Rodadas até o primeiro cair | 9,0 | 15,8 |
    | Rodadas até caírem todos | 13,7 | 22,6 |
    | Lacaios mortos | 27,8 | 40,7 |
    | Mortos por rodada | 2,0 | 1,8 |
    | Dano por turno de cada herói | 6,0 | 5,8 |
    | Curas por rodada | — | 1,1 |
    | Recuperar o Fôlego por rodada | — | 0,7 |

    - Usando curas e o fôlego, o grupo aguenta cerca de 65% a mais, e mata menos por rodada, porque gasta ações se mantendo de pé.

## Perguntas
- **Conjuração**: a fadiga que sobra pode ir para qualquer carta do herói, inclusive a de herói e a do foco? Ou só para cartas de magia?
- **Lanterna**: presa ao cinto (sem mão), como deixei? E a tocha precisa mesmo de mão livre?
- **Penumbra**: dar cobertura parcial contra ataques de longe está bom? E atacar no escuro, só ao lado e com desvantagem?
- **Devoções**: os 4 nomes são só para teste. Quer mandar as divindades do cenário?
- **Vila**: preços, recompensas e estalagem (5 por herói) estão no caminho? As cartas perdidas devem continuar entre missões, como fiz?
