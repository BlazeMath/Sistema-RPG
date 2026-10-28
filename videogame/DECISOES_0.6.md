# Versão 0.6 — decisões tomadas sem o Lucas (para revisar)

Tudo aqui é provisório e fácil de mudar. O cenário de exploração fica em `core/dados_exploracao.gd`: textos, faixas, custos e efeitos são só dados.

## Distribuição do dano (pedido do Lucas)

1. **Quando o herói sofre dano** (depois da resistência), abre uma janela. O jogador escolhe quanto vai para o escudo, quanto para a armadura e quanto para o baralho. Ela já vem com a sugestão antiga (escudo, depois armadura, depois baralho); Enter confirma.
2. **Limites**: escudo e armadura só recebem até a vida que têm. Dá para mandar tudo para o baralho.
3. **Cota de Malha** (muda a decisão 22 da 0.5): uma vez por cena, a armadura aceita qualquer quantidade de dano e fica com 1 de vida. Só a parte mandada para a armadura é segurada. Antes, o golpe inteiro era segurado.
4. **Ficha de Bloqueio**: corta o dano pela metade antes da escolha.
5. **A Muralha**: dá a ficha de Guarda quando escudo ou armadura recebem alguma parte do dano.
6. **Dano sem ataque** (queda, armadilha): também é distribuído, sem resistência.
7. **Defesa automática** (a caixinha na tela): continua só para o teste de defesa. A distribuição é sempre do jogador.

## Testes de atributo e interações

8. **Teste fora de combate**: 21 com o atributo como modificador, que não conta para estourar. As perícias ainda não existem, então valem 0. O nome da perícia já aparece no teste.
9. **Faixas de resultado**: seguem o livro onde existe tabela (escalar, nadar, saltar). Escalar, por exemplo: 2–8 cai · 9–10 não sobe · 11–15 · 16–19 · 20+. Nos outros testes, inventei os números de cada caso.
10. **Penalidade de armadura** nos testes de movimento (nadar, escalar, saltar, acrobacia): limite 19 com armadura média e 17 com pesada. Vale mesmo com a armadura quebrada, porque ela continua vestida.
11. **Vantagem por item**: depois de parar, o jogador pode trocar uma carta usada por uma carta da mão. Para facilitar, ele só clica na carta da mão e o jogo escolhe a carta usada que mais melhora o teste. Também pode confirmar sem trocar.
12. **Atributos dos testes**:

    | Teste | Atributo |
    | --- | --- |
    | Atletismo, Escalada, Natação | Força |
    | Acrobacia e Ladinagem | Destreza |
    | Fortitude | Constituição |
    | Rastrear e procurar | Percepção |
    | Investigação (deduzir) | Raciocínio |

13. **Custos**: nadar e escalar custam 1 ação Padrão, como no livro ("1 ação"). Saltar e correr pelas pedras custam 2 ações de movimento. Descanso curto e consertar a ponte custam o turno inteiro.
14. **Interagir**: o herói precisa estar ao lado do marcador. No rio, pode estar até 2 quadrados dele, desde que fique na beira, de frente para o outro lado.
15. **Atravessar**: o herói vai em linha reta do lugar onde está até a primeira casa livre depois do obstáculo.
16. **Dano de queda** (o livro ainda não define): 3 de uma queda de uns 2 metros, 2 para tombos menores (escorregar, cair na água).
17. **Cair** (a condição Caído ainda não existe): o herói perde o resto do movimento no turno.
18. **Descanso curto**: um por ponto de descanso, e não dá para descansar com inimigos em alerta. Se houver uma Ração de Viagem, ela é comida sozinha (−3 de fadiga). O Kit de Reparos devolve sozinho até 3 de vida, primeiro à armadura e depois ao escudo.

## Inimigos desatentos

19. **Desatento**: o inimigo não age até perceber um herói a até N quadrados, com linha de visão, no turno dele. Quem percebe alerta todos. Os valores atuais:

    | Inimigo | Percebe a até |
    | --- | --- |
    | Vigia | 3 |
    | Atirador | 3 |
    | Brigão dormindo | 1 |

    Passar o mouse sobre um inimigo desatento mostra a área que ele vê.
20. **Ataque surpresa**: atacado sem perceber, o inimigo defende só com as 2 cartas iniciais (desvantagem), e todos ficam alertas.
21. **Barulho**: falhar feio ao forçar o baú (2–8) alerta os inimigos.

## Cenário "A trilha do riacho"

22. **Objetivo**: levar a carroça de sementes. Matar todos os goblins não encerra a missão; ainda é preciso levar a carroça. Levar a carroça exige que nenhum inimigo esteja em alerta, ou seja, ir escondido ou vencer a luta antes.
23. **Pontos de interação**:
    - Riacho: nadar (Força) ou atravessar a pé (Constituição).
    - Pedras: saltar (Força) ou correr (Destreza).
    - Ponte quebrada: equilibrar-se (Destreza) ou consertar com a Corda, sem teste. Depois de consertada, os goblins também passam.
    - Baú: forçar (Força, vantagem com o Pé de Cabra), abrir com uma Gazua sem teste, ou destrancar (Destreza, com risco de agulha). Usei a vantagem da Vara de 3 Metros para notar a armadilha.
    - Rastros: Percepção, que no melhor resultado dá uma ficha de Preparo. Ou seguir os grãos, com Raciocínio.
    - Acampamento: descanso curto, ou revirar as cinzas (Percepção).
    - Paredão: escalar (Força, vantagem com a Corda), ou procurar um ponto melhor (Percepção). Achar esse ponto revela a fenda, mais fácil de subir.
    - Toca escura: Percepção, com vantagem da Lanterna.
    - Carroça: o objetivo.

## Inventário

24. **Todo herói recebe o Kit Inicial de Aventura** (os 8 itens) e o item básico da classe (Bandoleira de Armas para o Guerreiro). Os consumíveis continuam sendo escolhidos na criação, um de cada.
25. **O que funciona**:
    - Poção de Cura, Poção de Mana, Veneno Ácido e Antídoto: usados no inventário ou na barra de itens, com 1 ação.
    - Gazua: abre fechaduras.
    - Ração de Viagem: comida no descanso curto.
    - Corda, Pé de Cabra, Lanterna e Vara de 3 Metros: dão vantagem nas interações.
    - Kit de Reparos: funciona no descanso.
26. **Ainda sem efeito**:
    - Consumíveis: Tocha, Bomba de Fumaça, Pedra de Amolar e Óleo Antiespectral.
    - Kit e item de classe: Pederneira, Kit de Acampamento, Espelho e Bandoleira.
27. **Itens achados no mapa** vão direto para o inventário. Repetidos se acumulam (×2).

## Pequenas mudanças

28. **Rótulo do dano**: o dano do Goblin Atirador agora aparece como "Destreza", não como "Força".
29. **Botões**: "Nova batalha" virou "Recomeçar". Na exploração, a vitória aparece como "MISSÃO CUMPRIDA!".

## Para conversar na volta

- A distribuição do dano deve ter um atalho "sempre usar a sugestão" para quem quer jogar mais rápido?
- Valores de dano de queda e da condição Caído.
- Perícias na ficha: quantos pontos, quais começam treinadas.
- Escolha de consumíveis na criação: quantidade e preço (ouro?).
- Inimigo desatento: o alcance de percepção deve depender da Percepção do monstro e da Furtividade do herói?
- Interação com custo de "turno inteiro" (descanso, consertar a ponte): ok, ou deveria levar várias rodadas?
