# Versão 0.8 — decisões tomadas sem o Lucas (para revisar)

## Testes (regras do Lucas)

- A dificuldade é o valor alvo: tirar exatamente a dificuldade já passa. Com uma queda de 3 quadrados, a dificuldade é 18 e 18 basta.
- Um teste pode somar só um atributo, só uma perícia, ou os dois.
- A mesma ação pode ser feita de jeitos diferentes. Cada jeito tem sua dificuldade e seus efeitos.

Interpretações minhas:

1. **Na tela**, a ação aparece com um botão para cada jeito. Por exemplo, "Ler os rastros":
   - Sobrevivência, dificuldade 8;
   - só Percepção, dificuldade 14;
   - Investigação + Raciocínio, dificuldade 12.

   Cada botão mostra o modificador e a dificuldade. O que cada jeito descobre só aparece depois do teste.
2. **Uma tentativa por ação**: depois de tentar de um jeito, a ação some para o grupo todo, mesmo se falhou (a pista se perde). Isso evita repetir o teste até passar.
3. **Testes de dois atributos**: o formato aceita qualquer soma, mas por enquanto usei só "atributo", "perícia" ou "perícia + atributo".
4. **Nadar exige Natação 1**, como diz o livro ("senão afunda"). Sem ela, a opção aparece bloqueada.

## Grupo de 4 heróis

5. **Montar o grupo**: na tela de criação, marque até 4 heróis salvos na lista "Grupo". O grupo vale para a Missão, a Exploração e a Arena. O X1 usa só o primeiro herói. Os botões "Testar este herói sozinho" continuam jogando só com o herói aberto.
6. **Turnos**: cada herói tem seu turno na ordem da iniciativa, e o jogador controla todos. A barra de baixo mostra:
   - o herói da vez;
   - quem está fazendo um teste;
   - quem sofre dano.

   Os quadros acima da barra mostram o grupo; clicar num deles mostra as cartas e o inventário daquele herói.
7. **Derrota**: todos caídos ou um herói morto, como você definiu para o modo normal.
8. **Vida dos inimigos sobe com o tamanho do grupo**: +60% por herói a mais na arena, +50% para os goblins da missão e +60% para a Toupeira. O dano não muda. É só um ponto de partida para o playtest.
9. **Descanso curto vale para o grupo**: todos a até 4 quadrados do ponto de descanso descansam. Cada um come a própria Ração, se tiver.
10. **Habilidades com alvo aliado**:
    - Ao usar uma carta de cura ou proteção, o mapa marca os aliados possíveis em verde. Clique num deles.
    - Ressurgir aceita um aliado caído adjacente.
    - Curar um herói caído o levanta, porque cartas voltam ao baralho dele.
11. **Câmera**: em mapas grandes, ela vai até a unidade da vez. Dá para mover com WASD ou as setas e aproximar ou afastar com a roda do mouse.
12. **Alertas por grupo de inimigos**: brigar com os goblins não acorda a Toupeira.

## Classes novas (Ladino, Clérigo, Caçador e Mago)

13. **Ataque mágico**: dano = diferença + 2 + atributo de conjuração (Mago: Raciocínio; Clérigo: Sabedoria). O teste é só de cartas, como os outros. Os focos (varinhas, orbes) ainda não existem como itens; por enquanto qualquer herói dessas classes conjura.
14. **Alcances**:

    | Na carta | No jogo |
    | --- | --- |
    | Adjacente | 1 quadrado |
    | Curto | 4 quadrados |
    | Médio | 8 quadrados |
    | "Alcance 2" ou "alcance 3" | Esses quadrados |

    Todos precisam de linha de visão.
15. **Fichas nos inimigos** (o livro não dá números, então inventei):

    | Ficha | Efeito |
    | --- | --- |
    | Sangramento | 1 de dano por ficha no fim do turno de quem sangra |
    | Veneno | 1 de dano por ficha no início do turno |
    | Fogo | 1 de dano por ficha no início do turno; perde 1 ficha por turno (o fogo se apaga) |
    | Ferimento | +1 de dano no próximo golpe por ficha; sai ao ser usada |
    | Cegueira | o próximo ataque usa só as 2 primeiras cartas |
    | Confusão | o próximo alvo é escolhido ao acaso |
    | Atordoamento | −1 ação Padrão no próximo turno |
    | Medo | −1 de dano no próximo ataque |
    | Penalidade | −1 no limite do próximo teste |
    | Marcado | a carta fechada da defesa fica à vista; Condenar, Juízo e Tiro Mortal usam |

16. **Oculto** (Passo de Sombra): os inimigos só escolhem um herói oculto se não houver outro alvo. O herói sai do estado ao atacar.
17. **Ficha de Sombra** é só recurso. Ela é gasta pelas cartas do Ladino e não protege sozinha.
18. **Cartas que dizem "como parte de um ataque"** (Ataque Furtivo, Tiro Certeiro, Flecha Pesada, Quebrar a Fenda): usar a carta já é o ataque e gasta a ação Padrão.
19. **Simplificações**:

    | Carta | O que mudou |
    | --- | --- |
    | Mísseis Mágicos | os 3 de dano vão num alvo só |
    | Bênção Persistente | usada a qualquer momento do turno, uma vez por turno, em vez de no fim do turno |
    | Repertórios (Aprendiz de Fogo, Água, Terra, Ar, Luz e Sombra; Bênção e Salmos dos Salmos) | só o primeiro efeito (o ataque) funciona |
    | Mente Bélica | descarta sozinha a carta de menor valor da mão |
    | O Martelo da Luz | a ativada dá +2 de dano até o fim da cena (ainda não há "inimigos da devoção" nem tipos de dano) |
    | Sempre um Plano | recupera o último consumível gasto; uma vez por cena |

20. **Ainda sem efeito**: as cartas e metades que dependem de áreas, zonas, armadilhas, teleporte, luz, roubo, mortos-vivos ou demônios, magia de inimigos e ataque de oportunidade. Elas podem ser escolhidas na criação; o texto avisa "sem efeito".
21. **Itens de classe**:
    - Ferramentas de Ladrão: já dão vantagem para destrancar.
    - Símbolo Sagrado, Corda de Arco da Penumbra e Varinha Eletrizante: ainda sem efeito.
22. **Raças e backgrounds** continuam só Humano e Soldado. As outras cartas de raça e background ficam para a próxima etapa.

### Problema na planilha

23. **Flecha de Rede** (Caçador) custa 2 de fadiga, mas a carta tem limite 1. Nunca dá para usar. Corrija o custo ou o limite.

## Primeira fase longa: a fazenda Vale Seco

24. **História**: a guilda é contratada porque "goblins" atacam a fazenda. Na verdade, a Toupeira Atroz tomou a toca dos goblins, e eles roubam comida para sobreviver. Matar a Toupeira cumpre a missão.
25. **Áreas e o que dá para testar**:
    - **Fazenda**:
      - Conversar com o fazendeiro: Diplomacia, Intuição + Sabedoria ou Negociação + Diplomacia.
      - Examinar o celeiro: Percepção, Sobrevivência + Sabedoria ou Monstros + Raciocínio.
      - Descer no poço: queda de 4 quadrados (9 de dano, ou amortecer com dificuldade 19).
    - **Rio**:
      - Nadar.
      - Pular os pilares da ponte.
      - Consertar a ponte com a Corda, para o grupo todo passar.
      - Equilibrar-se no tronco: só Destreza, ou Acrobacia + Destreza.
      - Atravessar o vau.
    - **Acampamento goblin**:
      - Falar com Rokk: Diplomacia, Intimidação + Força ou Mentira. Se der certo, os goblins vão embora; se falhar, viram briga.
      - Espiar da moita (Furtividade + Destreza), para marcar os inimigos.
      - Pegar os mantimentos roubados, ou simplesmente lutar.
    - **Covil**:
      - Descanso curto no acampamento do caçador.
      - Escutar a entrada: Percepção ou Natureza + Sabedoria.
      - Preparar uma emboscada.
      - Pular do barranco: queda de 3 quadrados, e acorda a Toupeira.
      - Lutar contra a Toupeira Atroz. Os valores são para um grupo de 4:

        | Vida | Dano | Força | Resistência | Ataques por turno |
        | --- | --- | --- | --- | --- |
        | 90 | 6 | 4 | 2 | 2 |
26. **Goblins do acampamento**: ficam parados olhando até alguém encostar neles (percebem a 1 quadrado). Por isso dá para chegar perto e conversar.
27. **Água, fogueiras, cercas, poço e sacos**: agora não bloqueiam a linha de visão. Antes o rio bloqueava os arqueiros; nas cercas da arena, isso muda um pouco o equilíbrio.

## Para conversar na volta

- Uma tentativa por ação, ou cada herói pode tentar uma vez?
- Valores das fichas (Sangramento, Fogo, Veneno...) e o dano-base do ataque mágico.
- Escala de vida dos inimigos por tamanho de grupo (3 a 6 heróis).
- Ordem das próximas etapas: raças e backgrounds, áreas e zonas, ataque de oportunidade.
