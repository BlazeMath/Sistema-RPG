# Versão 0.21 — interface nova

## Tela mais limpa
1. **Fixo na tela, só o essencial**:
   - topo fino: título, rodada, objetivo, Registro e Menu;
   - quadro da iniciativa à esquerda;
   - barra de baixo mais baixa: herói, mão e botões.
2. **Menus que abrem ao passar o mouse**. Um clique no botão deixa o menu fixo; outro clique solta.
   - **Habilidades ▴**: as cartas. Ficam abertas enquanto você escolhe o alvo de uma carta.
   - **Ações ▴**: Concentrar, Recuperar fôlego, Planejar, tocha, lanterna, trocar arma, Foco...
   - **Registro (L)**: o histórico.
3. As caixinhas "Defesa automática" e "Dano: sempre usar a sugestão" saíram da tela e estão só no Esc → Configurações.
4. "Recomeçar" foi para o menu do Esc (fora da campanha).
5. **Mesa do teste** menor e mais baixa, logo acima da mão, com menos texto. Dá para ver os personagens e jogar cartas da mão.

## Iniciativa
6. Quadro com um nome por linha, na ordem. A vez de quem joga tem seta ▶ e fundo dourado.
   - Heróis em azul, inimigos em vermelho, caídos em cinza com ✝.
   - Inimigos que os heróis não estão vendo não aparecem (senão a lista entregaria quantos são). Na vez de um deles, aparece só "▶ ?".

## Mão em leque
7. As cartas da mão formam um arco, um pouco giradas e sobrepostas. A carta sob o mouse sobe.

## Fichas
8. **Ficha do herói** (C, botão "Ficha", ou botão direito no herói):
   - atributos, cada um com o que dá no valor base, no 3 e no 5 (✔ quando já vale);
   - perícias;
   - números de combate: dano da arma, resistência, velocidade, ações, mãos e luz;
   - equipamento com os efeitos;
   - consumíveis;
   - todas as cartas com os **dois lados** (o lado ativo marcado).
9. **Ficha do monstro** (botão direito num inimigo que você está vendo):
   - vida, patamar e papel, atributos, perícias e tipo;
   - ações (ataques por turno, reação, velocidade, dano e tipo, ataque de oportunidade, efeitos ao acertar, magias, reações, comportamento);
   - fichas e efeitos sobre ele.
   - **Fraquezas e resistências só aparecem depois de descobertas**: quando um ataque com aquele tipo de dano as revela, ficam anotadas para aquele tipo de inimigo durante a missão.

## Carta de arma
10. Cada herói tem agora uma **carta de arma** junto das habilidades:
    - Mostra a arma na mão: dano + atributo, tipo de dano, peso, alcance, duas mãos, Força mínima.
    - Guarda fichas como as outras cartas, inclusive o crítico do Foco Mortal, que põe Foco nela.
    - O verso é a segunda arma. O botão "Trocar para (arma)" troca de arma com as regras de custo; a carta vira junto e, como toda carta virada, perde as fichas.
    - As armas comuns ainda não têm ativadas; quando as incomuns e raras chegarem, os efeitos entram nesta carta.
    - Com a carta de arma, cada herói tem uma carta a mais para guardar fichas.

## Inventário (I)
11. No alto do inventário:
    - o **modelo 3D do herói** girando;
    - o que está em cada mão, no cinto e guardado, com o botão de trocar de arma (a lista muda na hora).
    - O modelo segura a arma padrão do pacote, não necessariamente a arma do herói.

## Criação
12. Cada atributo tem um **ⓘ** com o que ele dá (base, 3 e 5).
13. Abaixo dos itens aparece o texto de cada item escolhido: arma, segunda arma, armadura, escudo e foco.

## Avisos, efeitos e sons
14. **Carta que dispara brilha**: quando um efeito de carta acontece, a carta ganha uma borda dourada brilhante por uns 3 segundos, e o nome dela sobe em cima do herói ("✦ Folha de Carvalho").
15. **Efeitos visuais**:
    - cura = coluna de luz dourada em quem é curado;
    - magia = raio do conjurador até o alvo, com a cor do tipo de dano (Radiante amarelo-claro, Fogo laranja, Necrótico roxo...). O Feixe de Luz dispara um raio dourado.
16. **Sons** (sintetizados por mim, sem material de terceiros; tools/gerar_sons.py): passos, golpe, tiro, magia, acerto e cura. Seguem o volume da música e desligam junto (tecla M).

---

# Para você conferir
1. Os menus que abrem com o mouse estão bons, ou prefere as cartas sempre abertas como antes?
2. A iniciativa esconde os inimigos que não estão à vista. Prefere mostrar "?" para cada um, como antes?
3. Os sons e os efeitos são provisórios.
