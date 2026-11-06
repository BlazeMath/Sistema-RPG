# Versão 0.24 — correções do seu teste

## Tela de heróis
1. **A "segunda Bruna"**: a tela abria mostrando o herói atual (a Bruna) como se fosse um herói novo. Mudar a classe e salvar criava uma cópia. Agora:
   - a tela abre **editando** o herói atual, e salvar atualiza o mesmo herói;
   - "Novo herói" começa uma ficha em branco, com atributos zerados;
   - salvar com o nome de outro herói é recusado, com aviso.
2. **Botões no alto**: Novo herói, Salvar herói, Excluir e Voltar ao menu.
   - Excluir pede confirmação e tira o herói do grupo.
   - Os testes sozinho viraram uma lista com um botão "Testar" (antes eram vários botões que empurravam tudo para fora da tela).
3. **Editar**: clique num herói da lista, mude o que quiser e salve. Se mudar o nome, o grupo acompanha.
4. **O botão de salvar que sumia**: os achados novos (Gema do Pântano, Lasca de Cristal) quebravam a montagem da tela antes de ela chegar ao botão. Corrigido; os achados não aparecem mais na criação.
5. **Os dois repertórios**: testei Controlador do Arcano com Aprendiz de Fogo e Aprendiz de Terra, e os dois chegam à batalha e podem ser usados. O mais provável é que o herói jogado fosse a cópia da Bruna salva antes do segundo repertório (item 1). Se acontecer de novo, me diga o nome do herói.
6. A tela inteira agora fica sempre em 1280×720 proporcional (com faixas pretas se o monitor tiver outro formato). Antes ela esticava, e o texto podia sair da tela. Também aumentei as margens da criação.

## Cartas de herói (nenhuma aparece mais como "parcial")
7. **Novas partes que funcionam**:
   - **A Muralha**: a passiva (+1 de resistência com a armadura ou o escudo quebrados) e a reação. Quando um aliado vai sofrer dano de ataque, o jogo pergunta se o herói da Muralha paga 2 de fadiga e a Reação para receber o golpe no lugar.
   - **Estrela do Amanhecer**: quando um aliado receberia Ferimento, Veneno ou Fogo de um inimigo, o Clérigo paga 1 de fadiga e a ficha não entra. Por enquanto é automático.
   - **O Inabalável**: só 1 ficha por efeito inimigo; resistir a um efeito cura 1.
   - **O Feérico**: ignora terreno difícil; quem conjura contra você fica confuso.
   - **Palavra de Aço**: com um Juramento ativo, ignora Imobilizar.
   - **Brado da Horda** (ativada): aliados a até 4 casas avançam até 3 na direção do inimigo; quem chegar ao lado ganha um ataque de graça.
   - **Predador da Selva** (ativada): arma uma armadilha de imobilização ao seu lado.
   - **Trabalhador**: resiste a Concussão (−2).
   - **Seguidor da Chama**: reação de inimigo contra você dá 1 Reação.
8. **O que é do mestre ou de fora de combate** agora aparece como observação, sem "parcial":
   - Impostor: contato na vila;
   - Mil Ofícios: atitude de NPC;
   - Seguidor da Noite: descanso longo;
   - Incansável: penalidades de ambiente, que o jogo ainda não tem.
9. **O que ainda falta**:
   - O Atemporal: andar 1 ao gastar a Reação;
   - O Oportunista: fichas de Vantagem;
   - Ombro a Ombro: trocar fichas e andar fora do turno;
   - O Feérico: a esquiva e o crítico;
   - O Sobrevivente: trocar a ficha por Ferimento.

## Batalha
10. **Goblins no rio da fazenda**: agora atravessam pelos troncos.
    - Ao pisar no tronco, fazem um teste de equilíbrio (Destreza; o valor aparece em cima deles).
    - Se caírem, sofrem 2 de dano e perdem o resto do movimento.
11. **Ficha a escolher**: o quadro mostra de onde ela veio (a linha do Registro, como "Goblin Brigão põe 1 ficha de Imobilizar em Bruna").
12. **Foco como arma**:
    - Quem tem um foco de mão e **nenhuma segunda arma** troca entre a arma e o foco como troca de arma (o botão e a carta de arma).
    - Com o foco na mão: dá para conjurar ataques mágicos, e bater com ele conta como arma leve de Concussão.
    - Com a arma na mão: ataques mágicos e a carta do foco ficam travados ("troque de arma para pegá-lo").
    - Na criação: "Na mão no começo: segurando o foco". Já vem marcado para Mago e Clérigo.
13. **Alcance de tiro**: com arma de tiro, as casas na distância ideal ficam com um verde leve. Inimigo fora da distância ideal fica laranja (dá para atirar, com menos cartas); dentro, vermelho.
14. **Casas de interação**: contorno dourado na casa, além do "!".

## Testes e caixas
15. **Dificuldade sem número**: os diálogos e a mesa dizem só "muito fácil / fácil / médio / difícil / muito difícil".
    - Testes por faixas (nadar, escalar o rio) listam os resultados do pior ao melhor, sem os números.
    - As faixas do livro continuam nas dicas de Correr e Saltar.
16. **Resultado só depois de parar**: a mesa mostra cartas + perícia + atributo, sem dizer se passa. O resultado aparece quando você para.
17. **Mesa menor e à direita**: a câmera põe o seu personagem e o alvo à esquerda.
18. **Caixas de diálogo**:
    - abrem com uma animação curta;
    - têm um **X vermelho** para fechar (Esc também fecha);
    - escurecem o fundo e não deixam fazer outra coisa até fechar.
    - Quando a pergunta exige resposta (reação, ficha), o X não aparece.

## Interface
19. **Menu "Itens ▴"** ao lado de Habilidades e Ações: inventário e itens de uso. O Encerrar turno não cresce mais.
20. **Músicas**: cada uma tem 3 versões (tom, andamento e frase da melodia diferentes). Quando uma acaba, entra outra.

---

# Para você decidir
1. **Estrela do Amanhecer** é automática quando dá para pagar. Quer que pergunte?
2. **Foco na mão no começo**: deixei marcado para Mago e Clérigo. O Clérigo de espada e símbolo precisa trocar (1 ação) para bater de espada. Está bom?
3. **Goblins no tronco**: Destreza contra 12. Mais fácil ou mais difícil?
