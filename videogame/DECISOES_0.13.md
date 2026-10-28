# Versão 0.13 — balanceamento com suas respostas

## O que mudou

1. **Cura com 1 carta só no descarte**: ela é exilada e nada volta, como você confirmou (já funcionava assim). Só a Regeneração 1 da Constituição 3, que é automática, não dispara com menos de 2 cartas no descarte, para não prejudicar o herói sem ele escolher.
2. **Aggro**: corpo a corpo anda +1; à distância tem +1 no limite do 21 para atacar.
3. **Dano de referência dos inimigos**: 7 por ataque (o do Guerreiro), no lugar de 6. A vida de todos os patamares sobe junto.
4. **Diferença entre as classes** (meta: 5 contra 7):
   - Armas leves: +1 de dano (faca, florete, bastão e shuriken 3; arco curto 4).
   - Focos: +1 de dano (varinhas 3, orbes 2, cajados 4, sagrados 2; Marca da Punição 1).
   - É provisório: é a menor mudança que encontrei. Veja o que sobrou de diferença abaixo.
5. **Combate simples** (meta: 35–45% da vida do grupo):
   - O que mais gasta o baralho não é o dano sofrido: são as cartas usadas nos testes de ataque e de defesa, que vão para o descarte.
   - Com as suas fórmulas, um combate simples durava ~5 rodadas e gastava ~70% do baralho do grupo, embora o dano sofrido fosse só ~23%.
   - Para gastar ~40% (2 a 3 combates antes de descansar), lacaios e médios do combate simples ficaram com metade da vida (Encontros.calibragem_combate).
   - Em obstáculos, elites e chefes, os lacaios continuam com a vida cheia.
6. **Elite e chefe recalibrados** com o dano 7 e as armas novas:
   - Elite sozinho: 1,3× a vida e 2× o dano.
   - Elite com escolta: 1,35× a vida e 2× o dano.
   - Chefe: 0,75× a vida.
7. **Simulação mais completa**:
   - Fichas típicas de cada classe (atributos, arma, foco).
   - O Mago e o Clérigo atacam com a magia básica quando têm fadiga.
   - O Caçador atira de longe sem encostar.
   - Treino de dano por classe: um herói contra um boneco parado.
   - Os grupos alternam entre as 5 classes.
8. **Erro corrigido**: as cartas de repertório (Aprendiz de Fogo, Água, Terra, Ar, Luz e Sombra) não cobravam fadiga nem ação. O Mago podia atacar com magia sem parar. Agora custam 1 de fadiga e a ação Padrão, como no texto. Também o "arma leve: ao errar, devolva uma carta" não vale mais para ataques mágicos.

## Simulação (300 combates por linha, heróis sem estratégia; completa em Balanceamento_0.13.csv)

| Combate | Vitórias com 4 heróis | Com 2 | Vida que sobra (4) | Dano sofrido (4) | Meta |
| --- | --- | --- | --- | --- | --- |
| Obstáculo | 99% | 93% | 65% | 7% | — |
| Simples | 99% | 91% | 55% | 14% | 35–45% gastos |
| Elite sozinho | 42% | 29% | 20% | 87% | ~40% de vitória |
| Elite com escolta | 45% | 30% | 18% | 56% | ~40% |
| Chefe | 14% | 7% | 10% | 55% | ~10% |
| Toupeira Atroz (elite) | 44% | 30% | 21% | 86% | ~40% |

- "Vida que sobra" é o baralho do grupo no fim (cartas na mão, no baralho e no descarte que voltam no descanso). O combate simples gasta ~45%, então o grupo aguenta 2 combates e chega no terceiro no limite.
- O elite sozinho vence quase sempre derrubando todos; quando o grupo ganha, ganha por pouco.

### Dano por classe (um herói contra um boneco parado; inclui os ataques que erram)

| Classe | Dano por ataque | Dano por turno |
| --- | --- | --- |
| Guerreiro | 7,2 | 11,8 |
| Mago | 6,0 | 11,0 |
| Caçador | 5,0 | 9,0 |
| Ladino | 4,5 | 7,9 |
| Clérigo | 4,4 | 8,3 |

- Guerreiro e Mago estão onde você queria (7 e ~6).
- **Ladino e Clérigo ainda estão abaixo de 5.** A maior causa não é a arma: é a passiva da Força 3 ("causa dano mesmo errando"), que só o Guerreiro tem na ficha típica. Ela soma dano em quase metade dos ataques, que erram.
- O Caçador (ranged) ficou em 5: os ataques à distância **não** estão fortes demais. Ele ataca um pouco mais por turno porque não precisa andar até o alvo.
- Opções para fechar a diferença (escolha uma, ou nenhuma):
  1. Armas leves +2 no lugar de +1 (faca 4, florete 4, arco curto 5).
  2. Focos sagrados +1 (Símbolo Sagrado 3).
  3. Mudar a Força 3 para "dano mesmo errando só em ataques corpo a corpo com arma pesada", ou reduzir o valor.
  4. Deixar como está: o Ladino e o Clérigo ganham pelas cartas (Ataque Furtivo, curas), que a simulação usa pouco.
