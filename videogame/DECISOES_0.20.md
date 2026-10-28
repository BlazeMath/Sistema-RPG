# Versão 0.20 — regras e correções do seu teste

## Fim do turno
1. **Tela de fim do turno.** Ao passar (E ou botão), se houver algo a escolher, abre uma tela com:
   - de qual carta sai a fadiga (1 ponto; 2 com Fôlego de Viajante ou o crítico do Matador de Gigante, cada ponto numa carta que você escolhe);
   - Respirar Fundo: de qual outra carta sai a fadiga;
   - efeitos de fim do turno, para marcar: por enquanto a **Bênção Persistente**.
   - Se só uma carta tem fadiga e não há nada a marcar, o turno passa direto, sem tela. Por isso você viu a tela só no Clérigo.
2. **Bênção Persistente** agora é como no texto: no fim do turno, 1 de fadiga nela; você e os aliados a até 4 quadrados curam 1.
   - Toda cura já exila 1 carta do descarte antes, então ela não exila uma segunda.
   - A fadiga sai primeiro e depois a Bênção paga a dela (senão ela sairia de graça).
3. **Estrela do Amanhecer** (passiva): no início do turno do Clérigo, você escolhe o aliado a até 3 quadrados, e depois a carta dele de onde sai a fadiga.
   - Considerei "aliado" como outro herói, não o próprio Clérigo. Antes ela escolhia sozinha e podia ser o próprio.
4. Quando várias perguntas chegam juntas (Estrela, Sustentar, etc.), elas entram numa fila e aparecem uma de cada vez.

## Fichas
5. **No máximo 1 ficha de cada tipo por carta** (fadiga não é ficha).
   - Quem recebe fichas a mais e não tem carta livre daquele tipo perde a ficha.
   - Exceção: Fúria (a Fúria Crescente fala em 5 ou mais).
   - Os inimigos continuam sem limite, como você pediu.
   - Isso vale também para Sangramento, Veneno e Fogo: um herói com 3 cartas aguenta no máximo 3 de cada.
   - Cartas que pedem várias fichas (Passo de Sombra: 2 Sombra; Tiro Perfeito: 3 Mira) agora precisam desse número de cartas para guardá-las.
6. **Você escolhe a carta.** A ficha vai primeiro para a carta de herói; se havia mais de uma carta possível, aparece a pergunta "Em qual carta ela fica?". Fichas recebidas no turno dos inimigos são perguntadas quando a vez volta para um herói.
7. **Preparo**: só vira a carta em que está. O botão "Virar (Preparo)" aparece só nela.
8. **Mira**: o efeito agora é da ficha.
   - Durante qualquer ataque do herói, aparece "Descartar 1 Mira: −1 no limite do defensor".
   - Com o Tiro Certeiro e ataque à distância, o mesmo botão também soma +2 de dano por ficha.
   - Deixei a ficha valer em qualquer ataque, até corpo a corpo e mágico. Se for só à distância, me diga.
9. **Foco no teste**: se o herói tem Foco, o teste começa só com a carta aberta. Antes da fechada aparecem dois botões:
   - "Usar Foco: ver a próxima carta" (scry 1: deixar no topo ou mandar para o fundo);
   - "Receber a carta fechada".
   - Puxar ou parar também entrega a fechada.
   - Vale para ataque, defesa (se a defesa automática estiver desligada) e testes de perícia.
10. **Foco Mortal**: a passiva agora reduz só habilidades da própria arma, e nunca para menos de 1. Como as armas ainda não têm habilidades ativadas, ela não faz nada por enquanto. Antes reduzia as cartas de ataque do Guerreiro, o que estava errado.

## Cartas
11. **Folha de Carvalho**: um botão para cada ativada (Imobilizar e Ferimento). Vale para qualquer carta com mais de uma ativada no mesmo lado.
12. **Larápio**: virou pergunta. Quando um ataque em área vai causar dano, o jogo pergunta se você paga 2 de fadiga para sofrer só metade.
13. **Devorador de Grimórios** completo:
    - Passiva: um repertório "Aprendiz" custa 0 de XP na criação. O jogo escolhe o mais caro entre os que você pegou.
    - Ativada: uma troca de arma por rodada como ação livre.
    - A desencadeada (+1 carta no início da cena) e o crítico já funcionavam.
    - Limite: o jogo ainda não tem "grimório" como item. A troca livre vale para a arma de reserva; para trocar de foco (varinha, cajado) preciso de uma segunda vaga de foco na ficha.
14. **Avalanche e Contragolpe de Aço** mostram na carta o dano extra que somam agora (2 × ou 1 × a resistência da armadura).
15. **Cota de Malha**: corrigida. A armadura recebe no máximo a vida que tem; na primeira vez que chega a 0, volta para 1.
16. **Ombro de Ferro** (e cartas que andam e atacam): depois de escolher o alvo, se houver mais de uma casa possível, você escolhe de onde atacar, mesmo com inimigo ao lado. Ficar parado também vale.

## Movimento, descanso e nível
17. **Heróis atravessam aliados** (sem parar na casa deles). Inimigos continuam bloqueando.
18. **Descanso**: além de nenhum inimigo a até 9 quadrados, nenhum herói pode estar em combate. Em combate = algum inimigo em alerta que escolheria atacá-lo no próximo turno.
19. **Nível**: +1 de XP por nível (2 no nível 1, 6 no nível 5). O bônus dos inimigos continua: +25% de vida e +1 de dano por nível.

## Inimigos
20. **Lacaios com 11 de vida**, sem o corte pela metade no combate simples (antes ~4).
21. **Chefe com ~130 de vida para 4 heróis** (antes ~190).
    - Isso vale também para o Sir Aldric.
    - Na simulação sem estratégia, o chefe genérico caiu para 47% de vitórias e o Aldric para 37% (meta antiga: ~10%). Se quiser ele mais duro, compenso no dano.

## Tela
22. **Câmera**:
    - Não vai mais até um inimigo que os heróis não estão vendo no turno dele.
    - WASD e setas agora deslizam enquanto a tecla está apertada.
23. **Música**: nunca duas ao mesmo tempo. A de combate fica até não sobrar inimigo em alerta, e aí volta a do cenário.
24. **Quadros dos heróis** (nome e vida) somem enquanto a mesa do teste está aberta.
25. **Barra de vida**: verde = baralho, verde-claro = mão, vermelho = descarte (dá para curar), preto = exílio. Passe o mouse para ver os números.

---

# O que ficou para você
1. **Mira**: vale em qualquer ataque ou só à distância (item 8)?
2. **Estrela do Amanhecer**: o próprio Clérigo pode ser o aliado (item 3)?
3. **Chefe com 130**: está fácil na simulação. Compenso no dano, ou deixamos assim (item 21)?
4. **Devorador**: crio uma segunda vaga de foco (grimório/varinha) para a troca livre fazer sentido no Mago (item 13)?
5. **Fichas que passam do limite**: com 1 por carta, Sangramento, Veneno e Fogo param no número de cartas do herói. É isso mesmo (item 5)?

As próximas são a 0.21 (interface) e a 0.22 (monstros e tutorial).
