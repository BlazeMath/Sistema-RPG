# Versão 0.18 — modelos 3D, menu de pausa e jogos salvos

## Gráficos: modelos prontos de fonte segura
1. **Fonte**: os pacotes **KayKit**, de Kay Lousberg, baixados dos repositórios oficiais do autor no GitHub.
   - Licença **CC0** (domínio público): uso livre, inclusive comercial, sem obrigação de crédito. Deixei o crédito em `assets/modelos/CREDITOS.txt`.
   - Só o GitHub estava acessível daqui; sites como kenney.nl e itch.io ficaram bloqueados.
2. **Personagens animados**: parados respiram, andam pelas casas, viram para o alvo, atacam, sentem o golpe e caem.

   | Quem | Modelo |
   | --- | --- |
   | Guerreiro | cavaleiro com espada e escudo redondo |
   | Clérigo | cavaleiro sem elmo, escudo de brasão, tom claro (o pacote não tem clérigo) |
   | Ladino | ladino encapuzado com duas facas |
   | Caçador | ladino com besta (o pacote não tem arco) |
   | Mago | mago com cajado |
   | Goblins | bárbaro pequeno tingido de verde (machado; o atirador usa besta; o chefe é maior, machado de duas mãos) |
   | Esqueletos | esqueletos do pacote, com lâmina, besta ou machado e escudo (o Cavaleiro Ossudo é maior) |
   | Afogado | esqueleto tingido de verde-água |
   | Fantasma | esqueleto mago azulado e meio transparente |
   | Bruxa Morgana | maga tingida de roxo, com varinha e livro |

   - A Toupeira continua com a peça simples.
   - Herói inconsciente fica deitado e levanta quando volta.
3. **Cenários**:
   - **Fazenda**: casas e celeiro de verdade. Uma casa que ocupa várias casas do mapa vira um prédio só. Também poço, tenda, sacos, pedras e árvores.
   - **Cripta**: pilares, mesas, baús, caixões, altar com velas; nos cantos, velas, caveiras e escombros (só enfeite, não bloqueiam); paredes com pedras de tons e alturas diferentes.
   - **Pântano**: árvores secas.
   - O que não tem modelo continua com a peça simples de antes.
4. **Tamanho**: o jogo ficou cerca de 40 MB maior por causa das animações.

## Menu de pausa (Esc)
5. **Esc** na batalha (ou o botão "Menu (Esc)" do topo) e na vila abre a pausa:
   - Continuar.
   - Configurações: volume da música, música desligada, tela cheia (fica guardada), defesa automática e "dano: sempre usar a sugestão".
   - Salvar o jogo: só na vila; na batalha aparece apagado com o motivo.
   - Voltar ao menu principal.
   - Sair do jogo, que fecha o programa.
   - Esc também continua fechando janelas e cancelando escolhas, como antes. A pausa só abre quando não há nada para fechar.

## Jogos salvos
6. **3 espaços**. Cada um guarda:
   - o grupo e as fichas dos heróis (itens comprados e gastos inclusos);
   - a campanha: ouro, exílio de cada herói e missões cumpridas;
   - a data.
7. **Onde**:
   - **Salvar**: na vila, pelo botão "Salvar jogo" ou pelo Esc.
   - **Carregar**: no menu principal ("Carregar jogo salvo", vai direto para a vila) e na vila.
   - Ao carregar, os heróis do save substituem os de mesmo nome; os outros heróis salvos não mudam.
8. **No meio da missão não salva**. Para isso o jogo precisaria guardar a batalha inteira: cartas, fichas, posições e inimigos. Dá para fazer depois, se você quiser.

---

# O que ficou para você responder, revisar ou decidir

## Para decidir
1. **Progressão entre missões**: hoje o grupo ganha só ouro e itens. Quer que os heróis subam de nível, com cartas novas ou atributos? Se o PDF tiver regras de nível ou XP, eu sigo elas; se não, me diga o que ganha a cada missão. Sugiro que essa seja a próxima etapa.
2. **Salvar no meio da missão**, ou só na vila como está?
3. **Modelos**: o Clérigo é um cavaleiro sem elmo, o Caçador usa besta e os goblins são bárbaros verdes. Está bom para os testes? A alternativa é eu procurar outros pacotes CC0 no GitHub, mas não achei de goblin nem de clérigo.
4. **Contramagia** contra inimigo (0.17): teste automático de Raciocínio contra Sabedoria do conjurador + 14. Serve, ou o conjurador deve jogar a mesa?
5. **Troca de arma** (0.16): 1 ação (de movimento, senão a Padrão); arma grande custa 2; Bandoleira dá 2 trocas grátis por cena. Os números são meus.
6. **Arma do Panteão / Martelo da Luz**: numa conversa você mencionou trocar a Vantagem por uma ficha de Aprimoramento. No jogo ainda está a versão do PDF. Qual vale?
7. Pequenas simplificações minhas, para confirmar:
   - Lanterna da Fé ilumina em raio, não em cone.
   - Bênção Persistente pode ser usada durante o turno, não só no fim.
   - O Muro não tem pontos de vida (só bloqueia).

## Para revisar (números meus, provisórios)
8. **Vila**:
   - ouro inicial 60;
   - contratos: fazenda 80, cripta 120, pântano 150;
   - estalagem 5 de ouro por herói;
   - preços da loja (poção 12, antídoto 8, tocha 1, bomba de fumaça 15...).
9. **Luz**: raio da tocha, da lanterna, da fogueira e do fogo-fátuo.
10. **Inimigos novos**:
    - afogado, fantasma, esqueletos e Aldric (atributos, fraquezas e resistências);
    - a Bruxa com 1,6× a vida e 1,3× o dano. Na simulação: 40% de vitórias sem estratégia e 56% com habilidades, com 4 heróis.
11. **Divindades**: as 4 genéricas (Aurora, Martelo, Mãe Verde, Guardião) ficam até você mandar as do cenário.

## Para jogar e conferir
12. **0.15**: cripta escura e vila (compras, descanso, exílio entre missões).
13. **0.16**:
    - janela de fadiga da Conjuração;
    - mãos e segunda arma;
    - Foco (scry 1);
    - virar carta com Preparo ou ação;
    - cartas com cara de carta;
    - heróis prontos;
    - música.
14. **0.17**: o Pântano dos Afogados (noite, lodo, neblina, a Bruxa conjurando, Contramagia e Mana Densa).
15. **0.18**:
    - os modelos e as animações;
    - o Esc;
    - salvar na vila, sair, abrir de novo e carregar pelo menu.
