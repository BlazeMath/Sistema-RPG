# Versão 0.17 — próxima etapa: inimigos que conjuram e o Pântano dos Afogados

## Inimigos que conjuram
1. **Magias inimigas** são de dois tipos:
   - **Ataque mágico**, como o de um herói: diferença + dano da magia + Sabedoria.
   - **Ficha**: a magia põe uma ficha no alvo, que pode resistir com um teste.
2. **Reação dos heróis**: antes de uma magia acontecer, o jogo pergunta se alguém reage.
   - **Mana Densa**: o alvo descarta a carta de menor valor da mão e anula a magia que o tem como alvo.
   - **Contramagia**: 1 de fadiga e a Reação. Faz um teste automático de Raciocínio contra a Sabedoria do conjurador + 14, porque não há mesa para o inimigo nesse teste. Se passar, anula.
   - As duas estavam "sem efeito: inimigos ainda não conjuram"; agora funcionam.
3. **A Bruxa Morgana** tem duas magias:
   - **Maldição do Lodo**: 1 ficha de Penalidade; resiste com Espírito contra 16. Ela não repete em quem já tem a ficha.
   - **Raio de Lodo**: ataque mágico Necrótico que imobiliza.

## Inimigos novos (números meus)
4. **Afogado** (lacaio, morto-vivo):
   - Lento (velocidade 2) e nada.
   - Ao acertar, põe 1 Imobilizar, mas só se o alvo ainda não tiver nenhum. Sem esse limite, os afogados prendiam o grupo de vez na simulação.
   - Fraco contra Fogo e Radiante (+2).
5. **Fantasma Afogado** (médio, morto-vivo):
   - Flutua: atravessa a água e ignora o lodo.
   - Resiste a Corte, Perfuração e Concussão (−2); fraco contra Radiante (+3) e Fogo (+1).
   - Ao acertar, põe Medo.
6. **Bruxa Morgana**: elite com escolta (dois afogados e dois fantasmas para 4 heróis), conjuradora à distância, fraca contra Fogo.
   - Com o elite escoltado comum, ela ficou fácil demais na simulação: 77% de vitórias sem estratégia.
   - Por isso tem 1,6× a vida e 1,3× o dano (Pantano.CAL_VIDA_BRUXA e CAL_DANO_BRUXA).

## O Pântano dos Afogados (3ª missão)
7. **Noite de lua**: tudo fica pelo menos na penumbra.
   - Cobertura parcial contra ataques de longe em todo lugar.
   - Fogos-fátuos, fogueiras e tochas deixam pedaços claros.
   - Novo no cenário: "luz_ambiente".
8. **Terreno**:
   - Dois rios com pontes.
   - Lodo = terreno difícil.
   - Neblina na frente da cabana da bruxa = cobertura parcial.
   - Árvores mortas.
   - Novo no cenário: "zonas" fixas.
9. **Ordem pela sua filosofia**:
   - **Lago**: obstáculo de afogados submersos, que emergem quando alguém chega perto.
   - **Ruínas da capela**: combate simples de fantasmas e afogados, com um altar.
   - **Cabana do eremita**: descanso curto na fogueira e ervas.
   - **Cabana da bruxa**: elite com escolta.
   - Antes de tudo, o barqueiro dá conselhos, tochas e antídoto; se o grupo souber Ocultismo, marca a bruxa.
   - O barco afundado tem ouro.
10. **Pagamento**: 150 de ouro, mais até 55 de ouro achado (barco 45, altar 10). Entrou no quadro da vila e no menu.

## Simulação (150 combates, arena clara)

| Combate (4 heróis / 2 heróis) | Ingênua | Com habilidades |
| --- | --- | --- |
| Bruxa Morgana e a escolta | 40% / 12% | 56% / 21% |

- Com 4 heróis, fica perto da sua meta de elite: ~40% sem estratégia.
- Com 2 heróis fica bem mais difícil.
- No pântano de verdade, a penumbra dá cobertura a todos, e a bruxa conjura de dentro da neblina.

## Correção na simulação
- Na arena de teste, alguns combates não acabavam nunca: heróis presos sem ninguém ao alcance, ou um último inimigo "covarde" atrás da cerca.
- Agora o herói da simulação vira a carta que segura o Imobilizar, e esses cenários têm limite de 40 rodadas.
