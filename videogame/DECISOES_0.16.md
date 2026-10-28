# Versão 0.16 — suas respostas, mãos e segunda arma, visual novo e música

## Suas respostas aplicadas
1. **Conjuração**: quando a fadiga não cabe na carta, abre uma janela para você espalhar a sobra entre as suas outras cartas, uma ou várias, com − e +, como a distribuição do dano.
   - Se só uma carta tem espaço, vai para ela sem perguntar.
   - O sustento das zonas ainda paga sozinho: primeiro a própria carta, depois a de mais espaço.
2. **Lanterna** sem mão; **tocha** com mão (como estava).
3. **Penumbra** continua cobertura parcial.
   - **Escuro completo**: o ataque usa só 1 carta (a regra de 2 faixas fora da distância).
   - Continua valendo que não dá para mirar de longe quem você não enxerga.
4. **Devoções**: ficam as minhas.
5. **Cartas perdidas = exílio.**
   - Entre as missões, o descarte volta ao baralho.
   - O exílio só volta com o descanso longo na estalagem.
   - Heróis que voltam da 0.15 com descarte guardado começam a próxima missão sem ele.

## O que você notou jogando
6. **Ficha de Foco**:
   - Botão "Usar Foco (scry 1)", ação livre: descarta 1 Foco, mostra a carta do topo e você escolhe deixar no topo ou mandar para o fundo. É o uso do glossário: "descarte: scry 1".
   - Continua servindo de combustível para o Foco Mortal e as outras cartas.
   - O scry já aceita mais de uma carta; o Raio Radiante (scry 3) entra depois.
7. **Preparo ou ação para virar**:
   - Cada carta tem "Virar (ação)", e também "Virar (Preparo)" quando você tem ficha de Preparo.
   - Antes o jogo gastava o Preparo sozinho.
8. **Planejar**: estava mostrando um número de cartas igual ao Raciocínio. Agora mostra sempre as 2 do topo (4 com O Atemporal). Com Raciocínio 3, continua dando para reordenar.

## Mãos e segunda arma
9. **Mãos**:
   - A barra de baixo mostra o que está em cada mão: arma, escudo, foco e tocha.
   - Mostra também a arma de reserva e se a lanterna está acesa.
   - Arma de duas mãos ou grande ocupa as duas.
10. **Segunda arma** na criação (opcional), guardada.
11. **"Trocar por (arma)"** na batalha. Os custos são meus:
    - Troca normal: 1 ação; usa a de movimento e, se não tiver, a Padrão.
    - Com arma grande: 2 ações (texto do PDF: "trocar para ou desta arma custa duas ações").
    - **Bandoleira de Armas** (item do Guerreiro): duas trocas por cena sem custo (texto do item).
    - Se a arma nova não deixar mão livre, a tocha apaga.
    - Herói desarmado pode puxar a reserva.

## Visual
12. **Coluna da direita**: abas Cartas e Registro, com a altura toda entre o topo e a barra de baixo.
13. **Cartas de habilidade com cara de carta**:
    - Faixa com a cor da classe (Clérigo dourado e Mago azul, como no PDF) e o limite de fadiga em bolinhas.
    - Tags, com "✦ Conjuração" destacada.
    - O texto inteiro, as fichas da carta e o verso.
    - Botões: usar (com o custo), opções do repertório (cada uma com a sua descrição) e virar.
14. **A carta de herói mostra os quatro efeitos** à vista: passiva, ativada, desencadeada e ao critar 21.
15. Recomeçar e Menu foram para o topo, os botões de ação ficaram em 3 colunas, e a iniciativa não empurra mais o topo.

## Testar outros personagens
16. **Menu novo**: à direita, o grupo para jogar (até 4), escolhido por caixinhas entre os heróis salvos.
    - Vale para a arena, as missões, a trilha e a vila.
    - O botão **"Adicionar heróis prontos"** cria e salva um herói de cada classe, já válido, e monta o grupo com 4 deles:

      | Herói | Classe | Armas | Cartas |
      | --- | --- | --- | --- |
      | Bruna | Guerreira | espada e maça | Ombro de Ferro, Postura do Leão |
      | Lis | Ladina | faca e shuriken | Ataque Furtivo, Nunca Visto |
      | Tomas | Clérigo de Solenne | maça | Feixe de Luz, Toque Restaurador |
      | Iara | Caçadora | arco e faca | Preparar o Tiro, Flecha Aleijadora |
      | Aldo | Mago | faca e varinha | Aprendiz de Fogo, Aprendiz de Terra |

      Os cinco começam com poção e 2 tochas.
17. Na criação, "Testar este herói sozinho" ganhou a fazenda e a cripta.
18. Heróis incompletos saem sozinhos do grupo.

## Música
19. **Quatro músicas originais**, geradas por síntese, sem gravações de terceiros (tools/gerar_musica.py):

    | Música | Onde toca | Clima |
    | --- | --- | --- |
    | Menu e vila | menu e vila | pad, harpa e flauta em ré menor |
    | Exploração | ao ar livre, sem combate | mais leve, ré dórico |
    | Combate | quando há inimigo em alerta à vista | cordas em ostinato e tambores |
    | Cripta | no escuro, sem combate | drone, sinos e vento |

    - A troca entre músicas é suave.
    - **Tecla M** liga e desliga, e há um botão no menu.
    - O volume fica salvo.
    - É um começo para testar o clima; dá para trocar por música feita por alguém depois.
