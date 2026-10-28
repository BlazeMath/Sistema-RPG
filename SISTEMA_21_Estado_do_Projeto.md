# SISTEMA 21 — O que já está decidido

**Coleção Masmorras (MMR) · retrato do projeto em outubro de 2026**

Este documento serve para quem está chegando ao projeto: reúne num lugar só tudo o que já foi decidido para o
sistema. A base é o Livro de Regras 0.5, acrescido das decisões tomadas depois dele, como o fim das cartas com efeito
no baralho, o fim do Momentum e a revisão dos equipamentos. Onde algo ainda não está fechado, está marcado como
**em aberto**.

Ficam de fora o Bestiário e as Regras dos Monstros, que são documentos próprios.

---

## Sumário

1. A ideia em um minuto
2. Filosofia de design
3. O motor do jogo
4. Ações do turno
5. Habilidades e fadiga
6. Fichas, estados e tipos de dano
7. Armas, armaduras e escudos
8. Conjuradores e itens mágicos
9. Itens comuns, consumíveis e permanentes
10. Personagem: atributos, perícias, funções e criação
11. Carta de herói
12. Passagem de nível
13. O conteúdo pronto da coleção Masmorras
14. Convenções de redação das cartas
15. O que mudou no caminho
16. Questões em aberto
17. O videogame (projeto paralelo)
18. Arquivos de referência

---

## 1. A ideia em um minuto

- **O vinte‑e‑um substitui os dados.** Quando algo é incerto, o jogador puxa cartas do próprio baralho tentando
  chegar perto de 21 sem estourar.
- **O baralho é a vida e a energia.** O mesmo baralho de 52 cartas é a fonte da sorte e a reserva vital do
  personagem. Sofrer dano tira cartas do baralho, e baralho vazio significa cair. Cada teste arriscado gasta um
  recurso que também é a sobrevivência.
- **O personagem é montado com cartas:**
  - classe;
  - raça;
  - background (antepassado);
  - armas e armaduras;
  - cartas de habilidade;
  - a carta de herói.
- **Coleções temáticas.** O conteúdo sai em coleções vendidas em boosters, para jogadores e para mestres:
  - Masmorras (MMR), em desenvolvimento rumo à v1.0;
  - Lendas da Maldição (LDM);
  - Mercenários Mal Pagos (MMP);
  - Reforço aos Clássicos (RAC).
- **Sobre a mesa:**
  - o baralho pessoal de cada jogador;
  - as cartas de personagem e de habilidade;
  - as fichas (tokens);
  - do lado do mestre, um baralho compartilhado e as cartas de inimigo.
- **Inspirações declaradas:**
  - Magic: The Gathering — cartas *build‑around*, em que o defeito define o baralho, como Necropotence;
  - Descent: Legends of the Dark — itens com cargas e combos, e cartas de habilidade de dois lados;
  - A Ordem dos Arqueiros (Ranger's Apprentice) — o caçador que resolve as coisas de forma planejada.

---

## 2. Filosofia de design

Estes são os "porquês". Toda regra nova deve passar por eles.

### 2.1 O núcleo

- **Tudo dialoga com a dupla função do baralho**, que é sorte e vida ao mesmo tempo.
- **A mecânica vem antes do sabor.** Antes de perguntar "como fica bonito", pergunte "como isto se joga e o que faz
  o jogador sentir". O nome e o tema vêm depois.
- **A linha de derrota precisa existir.** Se o jogador não pode perder, a cena fica tediosa.
  - Em vez de uma *garantia*, dê um **recurso escasso** que o jogador decide quando gastar.
  - O exemplo é a primeira versão do Florete do Contragolpe: defesa garantida até 25 matava a tensão.

### 2.2 O jogo premia quem pensa

- **O jogo premia quem lê o inimigo e planeja:**
  - gastar os recursos com plano;
  - posicionar‑se taticamente;
  - coordenar‑se com os outros jogadores;
  - prever as ações e reações do inimigo.
- **O jogador que age sem pensar deve se ferrar.** É quem aceita todo efeito e não se posiciona.
- **Agressividade só vale quando vem de urgência**, como um relógio ou uma ameaça crescente. Nunca deve sobrar para
  quem joga no piloto automático.

### 2.3 As regras novas devem surpreender

- **Nada de regra "cinza".** Ajuste numérico óbvio, do tipo "diferença de 5 ou mais", não serve. A regra boa cria
  dilema.
- **Referência de tom:** *Intangível* só pode ser atacado no turno em que atacou corpo a corpo, e só por reação.
- **Alavancas centrais do sistema** — use‑as:
  - o baralho;
  - o 21 e o estouro;
  - as fichas;
  - cartas que viram;
  - a fadiga;
  - o impedimento;
  - a ação e a reação;
  - as habilidades;
  - as cartas usadas como armas.

### 2.4 Itens

- **Raridade:**
  - **Comum** é fraco, de início de campanha, mas com personalidade.
  - **Incomum** abre um *novo eixo de jogo*.
  - **Rara** é *build‑around*: um efeito claramente superior, amarrado a um defeito que **é** o eixo da estratégia.
- **"Conserto" não é upgrade.**
  - O incomum que só anula a penalidade da própria faixa é sem graça. Este é o erro mais recorrente; vigie‑o.
  - A rara deve responder à pergunta: "que forma de jogar isto me obriga?".
  - O defeito não é imposto. Ele reescreve como você joga.
- **Cada rara se pendura numa mecânica diferente:** a mão, o descarte, a fadiga, o crítico, as cargas, a posição, a
  resistência, o próprio 21.
  - O Machado da Sepultura usa o descarte.
  - O Montante do Frenesi faz o estouro virar coisa boa.
  - O Cajado do Condutor usa a fadiga.
- **Balanceie pela física do jogo.** O teto do Machado da Sepultura (+12) sai de existirem 12 figuras no baralho. Se
  possível, deixe o baralho impor o limite.

### 2.5 Cartas de habilidade

- **O custo é a cadência.** Custo 1 volta todo turno; custo 2 faz esperar ou virar a carta. Limite 0 não armazena fadiga; isso não determina sozinho se a habilidade é passiva ou se a carta pode virar.
- **Dois lados: um cria a situação, o outro a usa.** A Bomba de Fumaça gera Sombra; o Ataque Furtivo gasta Sombra.
- **Virar a carta é subótimo de propósito.** É um custo real e uma alavanca de design: forçar viradas é tática.
- **Restrição e Tags.** A Restrição é o que a carta *exige*; as Tags são o que ela *oferece*, para outras cartas se
  pendurarem. É assim que coleções diferentes conversam.

### 2.6 Classes

- **Estrutura fixa de 20 cartas:**
  - 3 estratégias de 3 cartas (função principal + secundária + uma terceira variável);
  - 6 meia cartas;
  - 2 metades de herói;
  - 3 cartas de 2 XP.
- **Cada classe tem uma ficha‑assinatura**, que é o seu motor: o Ladino gira Sombra; o Caçador, Mira.
- **Hierarquia de papéis explícita.** Ninguém é bom em tudo.
  - O Guerreiro é o melhor no combate direto.
  - O Ladino é o melhor interactor, mais forte fora do combate e de propósito abaixo do Guerreiro no combate.
  - O Caçador é o segundo melhor interactor, em terreno não urbano.
- **O combate das classes utilitárias usa seus recursos e condições próprios.** No Ladino, a ficha de Sombra representa a furtividade e pode ser gasta para aumentar o dano, sem exigir também vantagem ou o estado Oculto quando a carta não os pede. Veneno e Sangramento também fazem parte de suas ferramentas.
- **A jornada do arquétipo pode estar nas cartas.** A básica tenta com risco; a capstone domina.

### 2.7 Raças, backgrounds e heróis

- **Raça expressa a essência inata, nunca um papel de classe.** "Arqueiro élfico" é só uma classe de orelha
  pontuda, e "vantagem em testes" é bônus de ficha, não design.
  - O elfo: a relação com o tempo e o lado feérico.
  - O anão: a imobilidade e o juramento.
  - O halfling: a sorte e a coragem improvável.
  - O orc: a fúria que cresce.
- **Background é vivência, não posto.**
  - Dá competências simples e amplas, sobretudo sociais e mentais.
  - O Soldado é quem aprendeu a *obedecer e lutar em formação*. Não é comandante: esse papel será da classe Senhor
    da Guerra.
- **A carta de herói é a mais importante do personagem.**
  - Cada metade conta **uma** forma de jogar, e as quatro partes giram o mesmo motor. Exemplo: o Foco Mortal, cujas
    quatro partes alimentam o motor que fura armadura.
  - As duas metades de uma mesma classe contrastam: Foco Mortal fura armadura; A Muralha *é* armadura.
- **Efeitos de crítico** têm potência equivalente e sabores distintos, e precisam fazer sentido em qualquer teste.

### 2.8 Elementos do Mago

Cada elemento é uma filosofia traduzida em regra.

| Elemento | Filosofia |
|---|---|
| **Fogo** | Consumo, ímpeto, propagação. Toda magia de fogo consome algo: fadiga, movimento, fichas, a própria vida. |
| **Água** | Adaptação, persistência. Contorna em vez de bater de frente; é mais forte onde já há água; dita o ritmo (marés). |
| **Terra** | Constância, inflexibilidade. Resolve direto, cria obstáculos, resiste a efeitos, deixa o mago imóvel. |
| **Ar** | Turbulência, liberdade, ciclos. Reposiciona e envolve; não prende, conduz; "as coisas acontecem e passam". |
| **Luz** | Verdade, visão, velocidade. Revela o oculto, enxerga à frente (scry), age antes dos outros; efeitos efêmeros. |
| **Sombra** | Segredo, o outro lado. Primeiro cria a situação ideal (estar oculto), age e volta a se ocultar. |

### 2.9 Dano e fichas

- **Os tipos de dano são só etiquetas** de resistência e fraqueza.
- **A relação entre ficha e tipo é assimétrica.**
  - Ficha → tipo é garantido: todo dano da ficha de Fogo é Fogo.
  - Tipo → ficha não é: nem todo corte causa Sangramento.
- **Fichas voláteis e persistentes.** A distinção entre as que somem ao virar a carta e as que atravessam a virada é
  a regra mais importante do sistema de fichas.
- **Os inimigos não têm bônus de ataque nem de defesa.** Eles batem mais forte por efeitos de Força acima de 3 e
  aguentam mais por resistência a dano.
- **A dificuldade de um chefe vem da mecânica**, não de mais vida.
  - Exemplos:
    - auras;
    - uma ação extra que não é ataque;
    - dano reduzido enquanto um objeto do mapa existir;
    - lado vulnerável;
    - turnos alternados;
    - área telegrafada.
  - Um golpe de chefe deve chegar a uns 20 de dano, ou a cerca de 13 se atingir dois heróis.

---

## 3. O motor do jogo

### 3.1 O baralho, as zonas e a energia

**O baralho são 52 cartas comuns, sem efeito.** O esquema antigo de 26 cartas com efeito foi abandonado, porque o
playtest mostrou excesso de informação (ver a seção 15). A mecânica do personagem vem só das cartas de habilidade.

**As quatro zonas:**
- **Baralho** — de onde se compra; é a reserva de energia.
- **Mão** — cartas que o jogador escolhe jogar nos testes.
- **Descarte** — cartas perdidas por dano; podem ser recuperadas.
- **Exílio** — cartas perdidas pelo resto da cena.

**Dano, cura e compra:**
- **Dano:** para cada ponto de dano, mova uma carta do topo do baralho para o descarte.
- **Cura:** primeiro **exile ao menos uma carta do descarte**; depois devolva ao **fundo** do baralho tantas cartas
  quanto a cura. A cura nunca é infinita, e o corpo lembra de cada ferida.
- **Início de cada cena:** o personagem compra **2 + Sabedoria** cartas para formar a mão.
- **Baralho vazio:** o personagem cai e sai da luta.
- **Termos:**
  - **Triturar** — mover cartas do baralho direto para o descarte, sem ser dano;
  - **Exilar** — tirar uma carta pelo resto da cena;
  - **Scry N** — olhar as N próximas cartas e decidir a ordem delas.

### 3.2 O teste

1. Puxe as **duas cartas do topo** e some os valores. Valete, Dama e Rei valem 10; o Ás vale 1 ou 11, à escolha do
   jogador.
2. O objetivo é superar a dificuldade sem que a **soma das cartas** passe de 21.
   - O **atributo e a perícia** pedidos entram depois e **não contam para estourar**.
3. O jogador pode puxar mais cartas, uma de cada vez, até parar ou estourar.

**Estouro:** se a soma passar de 21, puxe **uma última carta**. O teste passa a valer essa carta sozinha, mais o
atributo e a perícia.
- Esta regra substituiu a antiga, em que estourar zerava o teste.
- Com a regra antiga, nunca compensava puxar a partir de 12. Com a atual, compensa arriscar até 14, e o risco volta a
  ser uma escolha real.

**Outras regras do teste:**
- **Cartas da mão** podem ser jogadas a qualquer momento em que você poderia puxar do baralho. Elas somam e **contam
  para estourar**.
- **Vantagem:** depois de ver o resultado, troque uma carta usada por uma da mão e reavalie.
- **Desvantagem:** jogue só com as duas cartas iniciais, sem puxar mais.
- **Crítico:** 21 natural com duas cartas (um 10 e um Ás). Vale no ataque, na defesa e nos testes comuns, para os
  efeitos que o citam.

**Faixas de resultado.** Correr, saltar, pular, escalar e nadar não têm dificuldade única: o valor do teste diz o
grau de sucesso. A faixa mais baixa (2–8) é a falha grave, como cair ou afundar, para que o risco alcance até o
especialista.

**Exemplo.** Destreza 3 + Ladinagem 2 = +5.
- Saem 7 + 5 = 12, e o teste vale 17. O jogador arrisca mais uma: sai um 6, total 18, e o teste vale 23.
- Se no lugar do 6 viesse um 10, estouraria. Ele puxaria uma última carta: um 4 faria o teste valer 4 + 5 = 9.

### 3.3 Combate

1. Atacante e defensor puxam duas cartas cada um. A primeira é **Aberta** (revelada); a segunda é **Fechada** (oculta
   do oponente).
2. O **atacante** puxa quantas quiser, até parar ou estourar.
3. Depois o **defensor** puxa quantas quiser. Ele sabe o que o atacante mostrou, mas não o que esconde. Agir em segundo
   é uma vantagem de informação, de propósito.
4. Quem estoura procede como no teste comum: puxa uma última carta, e só ela vale.

**Os testes de ataque e de defesa são só cartas.** Nenhum atributo ou perícia é somado a eles; entra apenas algum ±1
vindo de habilidades.

**Se o ataque for maior que a defesa, o golpe acerta:**

> **Dano = diferença entre os testes + dano da arma + atributo da arma − resistências do defensor.**

- O atributo é **Destreza** para armas leves e **Força** para as demais.
- O jogador atingido move uma carta para o descarte por ponto de dano.
- Toda carta que causa dano "igual à diferença" exige um teste de ataque.

### 3.4 Resistência e armadura

- **Resistência** reduz o dano recebido.
- **Armadura e escudo têm vida própria.**
  - O jogador pode mandar o dano para eles em vez do baralho.
  - Ao chegar a zero, o item quebra.
  - A armadura absorve no máximo a vida que lhe resta.
- **Sangramento, Fogo e Veneno** não podem ser direcionados à armadura.

### 3.5 Movimentação e impedimento

- **Mover:** uma ação de movimento dá deslocamento igual à **Velocidade** (padrão 3). O deslocamento pode ser
  fracionado: ande, aja e ande o resto.
- **Impedimento:**
  - Ficar adjacente a um inimigo, ou começar o turno assim, zera a velocidade na hora.
  - Enquanto impedido, a ação de movimento rende **1 quadrado**, nunca menos.
  - Cercado, o personagem continua impedido pelos demais inimigos.
  - Vale igual para os inimigos.
  - Escapam do impedimento: gastar **Sombra**, **Correr**, **Saltar** e **Parkour**.
- **Ataque de oportunidade é uma habilidade, não um direito de todos.**
  - Gasta a reação para atacar quem **sai** da área de alcance, ou quem muda de quadrado dentro dela.
  - Entrar na área nunca dispara o ataque.
- **Desengajar:** mover 1 quadrado para longe sem provocar ataque de oportunidade. Também é dado por habilidade.
- **Penalidade de armadura:**
  - Nos testes de movimento (Atletismo, Acrobacia, Escalada, Natação, Parkour) o limite do 21 cai para **19** com
    armadura média e **17** com pesada.
  - A Cota de Malha inclui Furtividade na lista.
  - Não afeta ataque, defesa nem magia.
- **Momentum:** a regra foi retirada (ver a seção 15).

### 3.6 Cena e descansos

- **Cena:** um conjunto de desafios que começa e termina num mesmo conflito, em geral cada combate ou cada
  exploração. Depois de um descanso curto, é sempre uma cena nova.
- **Descanso curto:** a Constituição define quanto se recupera ao Recuperar o Fôlego, e o Espírito quantas cartas
  voltam do exílio.
- **Descanso longo:** alguns itens o citam, como o Kit de Acampamento e a Pedra de Amolar.
- **Em aberto:** a regra completa dos descansos ainda não está escrita no livro de mesa. O videogame já usa uma versão
  própria (seção 17).

---

## 4. Ações do turno

Cada turno tem **1 ação de Movimento, 2 ações Padrão e 1 Reação**, mais ações livres a critério do mestre.
- A Padrão pode ser **rebaixada** para Movimento; o contrário não vale.
- Velocidade base: 3.

### 4.1 Movimento

| Ação | Custo | Regra |
|---|---|---|
| Mover | 1 mov. | Ganha 3 de deslocamento, fracionável. |
| Correr | 3 mov. (rebaixa as 2 Padrão) | Atletismo: 2–8 move 1 e cai · 9–12 normal · 13–16 2× · 17–21 3× · 22+ 4× + Atletismo. Ignora impedimento. Inimigos têm vantagem contra você até o seu próximo turno; provoca ataque de oportunidade com vantagem. |
| Saltar (horizontal) | 2 mov. | Atletismo: 2–8 1 quadrado e cai · 9–12 1 · 13–16 2 · 17–21 3 · 22+ 4. +1 se optar por cair; +1 se andou 3+ em linha reta antes; máx. 6. **É a forma de sair do engajamento.** Ignora impedimento; provoca ataque de oportunidade com vantagem. |
| Pular (vertical) | 1 mov. | Atletismo, em metros: 2–8 cai · 9–15 1,5 m · 16–20 2 m · 21+ 2,5 m. +0,5 m se andou 3+. Menos de 1,5 m não exige teste. |
| Escalar | 1 mov. | Escalada: 2–8 cai · 9–10 não sobe · 11–15 1 · 16–19 2 · 20+ 3. Sofre impedimento. |
| Nadar | 1 mov. | Exige Natação 1+, senão afunda. Mesmas faixas da escalada, com direção livre. Submerso inicia o relógio de fôlego. |
| Parkour | 2 mov. | Acrobacia contra dificuldade do mestre, para obstáculos que não pedem escalada (mesas, muros de até 2 m). Ignora impedimento; provoca ataque de oportunidade. |
| Levantar‑se | 1 mov. inteira | Sai de Caído; provoca ataque de oportunidade. |
| Deitar‑se | 1 mov. | Fica Caído. |
| Pegar item do chão | 1 mov. | No quadrado do item ou adjacente. |

Todas as ações de movimento com teste sofrem a penalidade de armadura.

### 4.2 Padrão

- **Ataque corpo a corpo** e **Ataque à distância** (este exige linha de visão).
- **Manobras de luta** (1 Padrão cada, no lugar de um ataque):
  - O teste é Luta contra Luta.
  - Só funcionam contra alvos do mesmo tamanho ou menores; cada degrau de tamanho acima dá −5 no limite.
  - **Agarrar:**
    - O alvo fica Agarrado.
    - Você fica Agarrando: −1 de velocidade, arrasta o alvo, os dois dividem o quadrado.
    - Exige uma mão livre.
  - **Derrubar:** o alvo fica Caído.
  - **Desarmar:**
    - A arma cai a uma distância dada pela margem: 1–3 no mesmo quadrado · 4–6 adjacente · 7–9 a 1 quadrado ·
      10–12 a 2…
    - Só vale para armas empunhadas e escudos.
  - **Atrapalhar:**
    - Luta contra Luta, ou Irritar contra Espírito, com a habilidade certa.
    - Cada 5 de diferença dá −1 no limite do próximo ataque ou defesa do alvo.
  - **Empurrar:** cada 5 de diferença empurra ou puxa o alvo 1 quadrado.
- **Estrangular** (sobre um alvo Agarrado): o relógio é a Constituição do alvo; ao zerar, ele vai a 0 e fica
  inconsciente.
- **Quebra de Membro** (sobre um alvo Agarrado): o relógio é a Força do alvo menos a sua, com mínimo de 1; ao zerar,
  aplica Danos Graves (em aberto).
- **Escapar de agarrão:**
  - 1 Padrão + 1 Movimento, com Luta contra Luta.
  - Ou forçar 1 quadrado com Força contra Força, levando quem agarra junto.
- **Auxiliar:** cada 5 de diferença dá +1 no limite do teste do aliado. Em combate, exige segurar uma Padrão e a
  Reação.
- **Concentrar:** compre 1 carta.
- **Planejar:** olhe as cartas do topo, em número igual ao seu Raciocínio, sem reordenar.
- **Recuperar o fôlego:** cure vida igual à sua Constituição.
- **Comandar:** só com Espírito 3+; um aliado compra 1 carta. Usos por cena = Espírito.
- **Virar carta** (de herói, arma ou habilidade): apaga as fichas voláteis dela.
- **Recarregar** (bestas).
- **Conjurar magia:** toda magia pode ser conjurada como Padrão.
- **Consumir item demorado.**
- **Interagir com o cenário** (interações não triviais).

### 4.3 Livres

- **Falar.**
- **Orientar:** um aliado ganha 1 ficha de Foco. Usos por cena = Diplomacia.
- **Consumir item rápido.**
- **Largar item.**
- **Entregar ou pegar item de um aliado.**
- **Abrir porta** e outras interações triviais.

### 4.4 Reação

Há 1 reação grátis por turno, e mais com fichas de Reação.

- **Desviar:**
  - Contra ataque à distância ou em área, move‑se com velocidade normal, gastando a Reação e uma ação de movimento
    reservada.
  - Se sair da área ou da linha de visão, deixa de ser alvo.
  - Não funciona contra corpo a corpo.
- **Preparar ação:**
  - Segure a ação no seu turno; ela dispara no gatilho escolhido.
  - Se o gatilho não ocorrer até o seu próximo turno, a ação é perdida.
- **Conjurar magia rápida:** magias com a tag *rápida* podem ser conjuradas como reação.

### 4.5 Ações dadas só por habilidade

- **Desengajar.**
- **Ataque de oportunidade.**
- **Mirar** (Caçador): gera fichas de Mira.
- **Contra‑atacar e aparar.**
- **Esgueirar:**
  - Teste de Furtividade.
  - Reduzir a velocidade dá +2 no teste por ponto reduzido, com piso de 1.
  - Quem pode perceber faz Percepção: o distraído joga 1 carta; quem não procura, 2; quem faz ronda, quantas o mestre
    quiser.

---

## 5. Habilidades e fadiga

- **Habilidades são cartas de dois lados**, no espírito de Descent.
  - Cada lado é uma habilidade, e a carta inteira compartilha uma **Restrição**.
  - A carta **emite Tags**.
  - Cada lado tem um **limite de fadiga**.
- **Fadiga:**
  - Ativar uma habilidade põe fichas de fadiga na carta.
  - No fim do turno o personagem retira **1 ficha de fadiga, de uma única carta à escolha**.
- **A carta não vira sozinha** quando enche: normalmente, virar custa uma ação e apaga as fichas voláteis. As persistentes
  continuam. Quando uma habilidade manda virar a carta, a virada faz parte da resolução da habilidade e não exige uma ação adicional.
- **Fadiga numa carta cheia:** em vez de pôr a ficha, exile 1 carta do descarte. Sem descarte, triture 1 carta.
- **Limite 0** não serve de depósito de fadiga. A carta pode virar pela ação normal ou conforme seu próprio efeito; outros custos da habilidade continuam valendo.
- **Só a fadiga ocupa o limite.** Foco, Guarda, Sombra, Penalidade e as outras fichas ficam na carta sem ocupar
  espaço.
- **Leitura do custo**, no estilo do Magic: tudo antes dos dois pontos é preço, tudo depois é efeito.
  - `2 de fadiga, Ação: …` paga 2 de fadiga e gasta a ação.
  - Outros preços entram na mesma lista: `Descarte uma carta`, `2 fichas de Foco`, `Exile esta carta`.
  - Sem nada antes dos dois pontos, a habilidade é passiva ou desencadeada.
- **Requisito.** Só pode ser algo que alguma fonte concede:
  - uma tag de escola: *Marcial*, *Magia Arcana*, *Magia Divina*;
  - um tipo de arma, armadura ou escudo;
  - uma raça ou um background;
  - um valor mínimo de atributo ou perícia.
  - Nunca se exige uma carta específica.
- **Sustentar o efeito:** pagar de novo o custo para manter um efeito contínuo. A redação é sempre esta.
- **Repertório:** um lado com uma lista de efeitos pequenos, dos quais se escolhe um por uso.

---

## 6. Fichas, estados e tipos de dano

### 6.1 Regras gerais das fichas

- **Toda ficha fica numa carta:** de herói, arma ou habilidade.
- **Quem escolhe a carta.** Se a fonte do efeito não diz em qual carta a ficha vai, quem escolhe é o alvo.
- **Virar a carta** apaga as fichas **voláteis**. As **persistentes** atravessam a virada e só saem pelo meio próprio
  de cada uma ou por efeitos que permitam remover fichas.
- **Remover uma ficha sem especificar o tipo** permite escolher qualquer tipo de ficha, inclusive Fadiga e fichas persistentes. As demais condições do efeito, como alvo e quantidade, continuam valendo. Água Benta é um exemplo desse efeito.

### 6.2 Fichas voláteis

| Ficha | Efeito |
|---|---|
| Fadiga | Custo das habilidades; é a única que ocupa o limite. |
| Foco | Descarte para fazer scry 1; várias cartas dão outros usos. |
| Preparo | Vira uma carta sua. |
| Pista | Gaste uma ação: compre 1 carta por ficha. |
| Guarda | Sofra um ataque no lugar de um aliado. |
| Bloqueio | Reduz à metade o dano de um ataque. |
| Sombra | Não ser alvo; sair de perto de um inimigo sem impedimento nem ataque dele. É o motor do Ladino. |
| Reação | Uma reação a mais. |
| Aprimoramento | +1 no limite do 21 (máx. 1 por carta). |
| Penalidade | −1 no limite do 21. |
| Medo | −1 no dano que o portador causa. |
| Ferimento | +1 no dano que o portador sofre. |
| Atordoamento | −1 ação. |
| Imobilizar | Dá o estado **Imobilizado** (ver 6.4). |
| Confusão | O portador atinge um alvo aleatório. |
| Cegueira | O portador não enxerga (detalhe em aberto). |
| Desarmado | Ver o estado. |
| Atormentado | +1 de fadiga por turno na carta; é a alavanca para forçar viradas. **Não é medo**: é pressão. |
| Maldição | Efeito definido pela fonte que a colocou. |
| Marcação | Permite ver a carta escondida do alvo. |
| Mira | Motor do Caçador; ganha‑se preparando o tiro. Ao atirar, descarte quantas quiser: cada uma dá −1 no limite do 21 do defensor e +2 de dano no acerto. |
| Fúria | Ficha do Orc (cartas de raça e herói). |

### 6.3 Fichas persistentes

| Ficha | Efeito | Como sai |
|---|---|---|
| Sangramento | Causa dano no fim do turno. | Medicina. |
| Veneno | Causa dano no início do turno. | Antídoto. |
| Fogo | Causa dano no início do turno e espalha. | Água ou cenário. |

**Em aberto:** Ácido e Infectado provavelmente serão persistentes.

**Cuidado com a sobrecarga.** Foco e Sombra estão acumulando usos. Em algum momento, cada uma precisa ter todos os
seus usos listados no glossário.

### 6.4 Estados

| Estado | Efeito |
|---|---|
| Caído | Cobertura parcial contra ataques à distância, mas dá vantagem a golpes corpo a corpo contra ele. Ataca de perto com desvantagem; velocidade 1; levantar custa um movimento inteiro e provoca ataque de oportunidade. |
| Impedido | Velocidade zero; o movimento rende 1 quadrado. |
| Imobilizado | Vem da ficha Imobilizar. O personagem perde a ação de Movimento do turno e não pode rebaixar Padrão para Movimento. Dura até gastar uma Padrão para virar a carta que tem a ficha. |
| Agarrado | Imóvel, preso por outro personagem, no mesmo quadrado. |
| Agarrando | −1 de velocidade; arrasta o alvo; exige uma mão livre. |
| Desarmado | Sem a arma: não usa as habilidades dela e ataca com os punhos, sem bônus de dano. Defender‑se de armas com os punhos é sempre com desvantagem. |
| Oculto | Havendo outro alvo válido, não pode ser escolhido; os ataques feitos dali são furtivos. Sai ao atacar ou ao ser revelado. É um *estado*; a Sombra é um *recurso*. |
| Inconsciente | A zero de energia, fora da luta. |

**Medo × Atormentado.** Medo é a ficha de medo; Atormentado é pressão e fadiga. Não confundir.

### 6.5 Tipos de dano (18)

| Grupo | Tipos |
|---|---|
| Físicos | Corte · Perfuração · Concussão · Sangramento |
| Elementais | Fogo · Gelo · Raio · Ácido |
| Toxinas | Veneno · Salino |
| Vida e morte | Radiante · Necrótico · Dreno · Espiritual |
| Mente e sentidos | Psíquico · Som |
| Ambientais | Sufocante · Radiação |

O livro 0.5 ainda dizia "Impacto"; os documentos mais recentes adotaram **Concussão**.

---

## 7. Armas, armaduras e escudos

O texto que vale é o da revisão de equipamentos de setembro (`Equipamentos_Cartas.pdf`, 155 cartas).

### 7.1 Armas corpo a corpo

Duas dimensões independentes, **Peso** e **Tamanho**, formam uma grade de 9 armas. Cada combinação existe nas três
raridades.

| Peso \ Tamanho | Pequeno (1) | Médio (1) | Grande (2) |
|---|---|---|---|
| **Leve** — 2 + Destreza | Faca | Florete | Bastão |
| **Média** — 4 + Força (Força ≥ 1) | Espada Curta | Espada Longa | Lança |
| **Pesada** — 6 + Força (Força ≥ 2) | Maça | Machado de Guerra | Montante |

- **Peso Leve:** ao errar um ataque, devolva uma das cartas usadas no teste para o fundo do baralho.
- **Peso Pesado:** −1 de Velocidade; ao errar um ataque, triture 1 carta.
- **Tamanho Pequeno:** ao atacar, você pode somar ou subtrair 1 da soma das cartas. Depois disso, defende‑se com as
  cartas reveladas até o seu próximo turno.
- **Tamanho Grande:** alcance 2; trocar para esta arma, ou dela para outra, custa duas ações.

### 7.2 Armas à distância

| Arma | Dano | Alcance | Nota |
|---|---|---|---|
| Shuriken | 2 + Des | Curto (3) | — |
| Machado de Arremesso | 4 + For | Médio (5) | Fica no quadrado do alvo até ser recuperado. |
| Javelin | 6 + For | Longo (7) | Idem. |
| Arco Curto | 3 + Des | Curto e Médio | — |
| Arco Longo | 4 + Des | Médio e Longo | — |
| Besta Pesada | 6 fixo | Médio e Longo | Ignora resistência; não soma atributo; exige Recarregar. |

**Regra de distância:**
- Cada arma tem um **alcance ideal**: curto, médio ou longo.
- **Uma faixa fora:** só as duas cartas iniciais, sem puxar mais, mas ainda pode jogar cartas da mão.
- **Duas faixas fora:** puxa só 1 carta do baralho e joga só 1 da mão.
- Além do alcance máximo, não há ataque.
- Todo ataque à distância exige linha de visão.

### 7.3 Armaduras e escudos

| Proteção | Vida | Resist. | Regra da categoria |
|---|---|---|---|
| Sem armadura | 0 | — | Ao vencer a defesa, devolve ao baralho a carta usada nela. É o único estilo que "recupera fôlego ao esquivar". |
| Leve | 4 | 2 | Ao ter sucesso na defesa, devolve ao baralho uma carta usada no teste, escolhida ao acaso. |
| Média | 9 | 3 | Exile 1 carta do descarte por turno; limite 19 nos testes de movimento. |
| Pesada | 16 | 3 | +1 no limite dos testes de defesa; exila 1 carta do descarte no início do turno; −1 de Velocidade; tritura 1 ao usar mais de uma ação de movimento no turno; limite 17 nos testes de movimento. |
| Escudo leve | 5 | 1 | Ocupa uma mão. |
| Escudo pesado | 10 | 2 | Ocupa uma mão. |

Escudos impedem o uso de duas armas e de armas de duas mãos.

### 7.4 Catálogo de armas e proteções

Cada uma tem texto próprio nas cartas.

- **Corpo a corpo:**
  - **Incomuns:** Estilete, Florete de Duelista, Chicote, Francisca, Espada do Mestre‑Ferreiro, Alabarda,
    Maça‑Estrela, Machado Barbado, Montante de Batalha.
  - **Raras:** Adaga da Mão Vazia, Florete do Contragolpe, Cajado do Condutor, Lâmina do Vento, Gládio Inquietante,
    Lança da Muralha, Quebra‑Elmos, Machado da Sepultura, Montante do Frenesi.
- **À distância:**
  - **Incomuns:** Adaga Balanceada, Machete Farpado, Lança Espiral, Arco Recurvo, Arco de Teixo, Besta da Seta Dupla.
  - **Raras:** Leque de Lâminas, Machado Sedento, Lança Trovejante, Arco das Sombras, Arco da Maré, Balestra de
    Cerco.
- **Armaduras:**
  - **Comuns:**
    - Couro do Batedor — bolso secreto;
    - Cota de Malha — uma vez por cena volta a 1 de vida, mas dá desvantagem em Furtividade;
    - Arnês de Placas — vantagem em Intimidação.
  - **Incomuns:** Couro Élfico, Brunea de Escamas, Armadura Samurai Temperada.
  - **Raras:** Manto do Vento, Couraça do Contra‑Ataque, Peitoral de Dalpnor.
- **Escudos:**
  - **Incomuns:** Broquel Ágil, Escudo de Investida.
  - **Raros:** Placa de Luz, Scutum da Legião.

---

## 8. Conjuradores e itens mágicos

### 8.1 Clérigo

- A **Divindade** concede as tags de escola básicas.
- Usa quatro tipos de habilidade:
  - conhecimento;
  - repertório (Textos Sagrados e cartas de repertório);
  - melhoria de conjuração;
  - magias treinadas, mais eficientes que a versão do Texto Sagrado.

### 8.2 Mago

- **Não tem divindade: coleciona Chaves.**
  - Cada Chave é uma carta **Aprendiz de [Elemento]** que concede a tag do elemento nos dois lados.
  - O lado A é um repertório de truques; o lado B, uma habilidade média de combate.
- **Elementos:** seis — Fogo, Água, Terra, Ar, Luz e Sombra.
- **"Seu elemento".** As magias dos arquétipos falam em "seu elemento" e exigem ao menos uma Chave.
- **Repertório arcano básico**, não elemental, que todo mago pode usar: Mão Mágica, Mísseis Mágicos, Contramagia,
  Armadura Arcana, Telepatia e Detectar Magia.

### 8.3 Tags e conjuração

- **Tags de escola:**
  - **Magia Arcana** (mago) e **Magia Divina** (clérigo) são requisitos e ganchos de combo.
  - A tag **Aprendiz** identifica as habilidades básicas de magia.
- **Habilidade e magia:** um efeito que modifica o custo de magias só afeta magias. Água Benta é uma habilidade, não uma magia; a redução do Cajado do Condutor não se aplica a ela. A classificação do efeito deve ser respeitada, sem concluir que toda habilidade de conjurador é magia.
- **Custo mínimo das magias:** reduções no custo de Fadiga de uma magia nunca podem fazer seu custo final ficar abaixo de 1, mesmo quando várias reduções são combinadas. Essa regra não cria custo de Fadiga para habilidades que não são magias. Conjuração Perfeita permite conjurar uma magia por turno pagando apenas 1 de Fadiga; os outros custos continuam valendo.
- **Conjuração** é um símbolo nas magias.
  - A fadiga da magia pode ir para **outra carta ou item com espaço**.
  - Isso transforma capacidade de fadiga em recurso de construção, e existem itens "bateria" para isso.
  - A fadiga espalhada continua sendo fadiga.
  - O símbolo está aplicado às 44 faces de mago, clérigo e ladino que espalham fadiga.
- **Velocidade da magia:**
  - Magia *rápida* pode ser conjurada como reação.
  - Toda magia pode ser conjurada como ação Padrão.

### 8.4 Itens de conjurador

- **Foco** (Mago e Clérigo):
  - Ocupa uma mão e não é arma corpo a corpo; é "a arma" dos ataques mágicos, e seus bônus somam neles.
  - Oferece até três coisas: um depósito de fadiga, um auxílio passivo e uma habilidade ativada.
  - **Focos arcanos:** Varinha de Cristal, Cajado do Aprendiz, Cajado de Batalha, Orbe de Concentração, Orbe de
    Proteção.
  - **Focos sagrados:** Cálice da Vida, Relicário do Guardião, Marca da Punição, Turíbulo das Bênçãos, Escrituras de
    Maftoné, Rosário da Devoção.
- **Ataque mágico:** é feito com o foco e usa o atributo de conjuração da classe. Conta como magia para tudo que se
  refere a magia.
- **Grimórios** (Mago) exigem a tag do elemento.
  - **Básicos:** um por elemento.
  - **Raros:** são de magos nomeados e exigem **duas** tags elementais: Códice das Cinzas, Sussurros do Breu, Códice
    da Chama Negra, Grimório do Lodo, Estudo de Geofótons, Portfólio do Luar Marinho.
- **Textos Sagrados** (Clérigo): A Batalha dos Anjos, A Criação da Luz, Os Ensinamentos Divinos, As Leis
  Fundamentais, O Fogo Purificador.
- **Pedras de Runa:**
  - Consumíveis de "magia presa no texto", usáveis por **qualquer classe**.
  - Cada uma traz 3 opções: escolha uma, gaste uma ação, e a runa é consumida.
  - Não concedem a tag do elemento.
  - No futuro, servirão de componentes de fabricação.
- **Amuletos divinos:**
  - Acessórios que não ocupam a mão e ligam o portador a um deus de **domínio concreto**. Domínios genéricos
    ("deus da guerra") estão vetados.
  - Os seis: Pacenas, Deus da Neblina · Grevha, Deus da Vanguarda · Nebtor, Deus da Escrita · Vael, o Deus Único, a
    Chama Purificadora · Kanil, Deus do Milho · Kagen, Deus do Umbral.

---

## 9. Itens comuns, consumíveis e permanentes

- **Itens consumíveis** se gastam ao usar.
  - **Comuns:** suprimentos básicos.
  - **Incomuns:** por papel do arquétipo.
  - **Raros:** por classe.
- **Itens não consumíveis** são permanentes. Os que têm limite de fadiga e habilidade ativada funcionam como uma
  carta: Símbolo Sagrado, varinhas, focos, grimórios.
- **Consumíveis:**
  - **Comuns:** Poção de Cura Pequena, Tocha, Antídoto, Ração de Viagem, Bomba de Fumaça, Pedra de Amolar, Veneno
    Ácido, Poção de Mana Pequena, Óleo Antiespectral, Gazua.
  - **Incomuns:** Poção de Pele de Pedra, Poção Carmim, Incenso de Jasmim, Frasco de Piche, Poção Turquesa.
  - **Raros:** Sangue de Batalha, Flocos de Sombras, Água Abençoada, Flecha Explosiva, Pergaminho do Desencantamento.
- **Permanentes:**
  - **Comuns:** Corda, Pé de Cabra, Pederneira, Kit de Reparos, Kit de Acampamento, Lanterna, Vara de 3 Metros,
    Espelho de Bolso, Bandoleira de Armas, Ferramentas de Ladrão, Símbolo Sagrado, Corda de Arco da Penumbra,
    Varinha Eletrizante.
  - **Incomuns:** os itens desta faixa foram desenhados pelo Lucas, que substituiu a proposta original inteira:
    Paraquedas Élfico, Bússola do Rumo, Equipamento de Pesca, Gancho de Escalada, Grilhão de Ferro, Manopla de
    Bronze, Botas de Lince, Pergaminho Ancestral, Manto Camuflado, Anel do Iniciado, Elmo de Touro, Bainha Impetuosa,
    Cachecol da Parceria, Cinto Estelar, Botas Seccundas.
  - **Raros:** Carta da Sorte, Ampulheta Trincada, Máscara do Impostor, Selo de Sangue, Colas Vinculador, Grevas do
    Vazio, Espelho Arcano.

---

## 10. Personagem: atributos, perícias, funções e criação

### 10.1 Atributos

São nove atributos, na escala de 0 a 5. Cada um tem um efeito **principal** e dois limiares acumulativos, em **3** e
em **5**.

| Atributo | Principal | Em 3 | Em 5 |
|---|---|---|---|
| Força | Soma no dano corpo a corpo de armas médias e pesadas | Causa dano igual à Força mesmo errando | Causa Força + arma mesmo errando |
| Destreza | Soma no dano à distância e no corpo a corpo leve | Pode somar 1 no ataque (para fechar 21) | Move 1 ao se defender com sucesso |
| Constituição | Quanto cura ao Recuperar o Fôlego | Regeneração 1 | Ao curar, devolve cartas do exílio ao baralho |
| Percepção | Raio de percepção passiva | O defensor joga com a 2ª carta revelada | Olha o topo do baralho do defensor |
| Sabedoria | Cartas extras compradas no início da cena | Scry 1 antes da 2ª carta de toda ação | Mulligan ao comprar no início da cena |
| Raciocínio | Cartas olhadas ao Planejar | Ao critar, compra 1 e descarta 1 | Pode tombar em vez de descartar |
| Espírito | Cartas que voltam do exílio ao descarte no descanso curto | Ganha a ação Comandar | Ao Comandar, o aliado compra duas |
| Mentira | Ações de Blefe na cena | Devolve uma carta sem efeito usada no ataque | Devolve também carta com efeito* |
| Diplomacia | Ações de Orientar na cena | Conversar com NPCs não gasta ação em combate | Limite dos testes sobe para 22 |

- **Blefe:** depois que o defensor inimigo termina, escolha uma carta do atacante e embaralhe‑a; jogue a do topo.
- **\*Mentira:** os limiares de Mentira citam "carta com efeito", que não existe mais (o baralho agora é todo de
  cartas comuns). Precisam de nova redação (em aberto).

**Distribuição na criação:** dois atributos em 3, dois em 2, três em 1 e dois em 0. Isso define quais efeitos de
limiar o personagem tem.

**Teto de atributo por nível (em avaliação):** 3 no nível 2, 4 no nível 5 e 5 no nível 8.

### 10.2 Perícias (13 por categoria)

| Categoria | Perícias |
|---|---|
| **Físico** | Acrobacia · Atletismo · Cavalgar · Direção · Escalada · Fortitude · Furtividade · Iniciativa · Ladinagem · Luta · Natação · Pontaria · Reflexos |
| **Mental** | Arcanismo · Ciência · Guerra · História · Investigação · Literatura · Medicina · Monstros · Natureza · Ocultismo · Ofício · Religião · Sobrevivência |
| **Social** | Acalmar · Adestramento · Arte · Atuação · Contatos · Intimidação · Intuição · Irritar · Jogatina · Liderança · Negociação · Nobreza · Política |

- Percepção, Diplomacia e Mentira são **atributos**, não perícias.
- Atletismo cobre o esforço geral; Escalada e Natação saíram dele.
- Acalmar e Irritar formam um par.
- **Casos de fronteira para revisar:** Ofício, Sobrevivência, Ladinagem e Nobreza.

### 10.3 Funções (papéis)

Toda classe combina uma função principal e uma secundária.

| Função | Papel |
|---|---|
| **Striker (Aggro)** | Dano. |
| **Tank** | Absorver e redirecionar dano; proteger. |
| **Support** | Curar e fortalecer. |
| **Control** | Fichas, zonas e marcações. |
| **Interactor** | Mobilidade e cenário, dentro e fora do combate. |

### 10.4 Criação (jogo de mesa)

1. Escolha **raça** e **background**.
2. Escolha **1 ou 2 classes**.
3. **Distribua os atributos** (seção 10.1).
4. **Baralho:** 52 cartas comuns.
5. **Cartas de habilidade:** o personagem começa no **nível 2**, com **2 de XP**, ou seja, duas habilidades de 1 XP
   ou uma de 2 XP.
6. **Equipamento:** até duas armas e uma armadura ou escudo.
7. **Carta de herói:** escolha **2 metades** (seção 11).
8. **Fonte de magia,** para conjuradores: a divindade, no Clérigo; as Chaves elementais, no Mago.

---

## 11. Carta de herói

- **É a carta mais importante do personagem.**
- **Duas metades, escolhidas** entre as opções da classe, da raça e do background do personagem.
- **Cada metade traz quatro efeitos** e um limite de fadiga:
  - **ativada**;
  - **passiva**;
  - **desencadeada**;
  - **ao fazer 21**.
- **As quatro partes contam a mesma história.**

---

## 12. Passagem de nível

### 12.1 O que está decidido

- **Quem dá o nível é o mestre**, conforme o andamento da história. Não existe XP por monstro morto.
- **Subir de nível aumenta o XP**, e o XP é o que compra cartas de habilidade.
- **Além do XP**, a cada nível o personagem escolhe:
  - +1 em um atributo, **ou**
  - +1 em duas perícias diferentes.
- **Custo das habilidades.** Elas custam 1, 2 ou 3 de XP.
  - Uma carta de custo N só passa a valer a pena no nível N+1, quando deixa de ser a única carta.
  - Por isso a mão de habilidades se estabiliza sozinha entre 2 e 4 cartas.
- **Contrapeso da fadiga.**
  - Cada carta é um depósito de fadiga.
  - Com menos cartas, fortes, o personagem "engasga" mais cedo.
  - Por isso as cartas de 2 e 3 XP têm limites de fadiga generosos.
- **Calibragem.** Uma carta de 2 XP deve valer **cerca de 2,3 a 2,5 vezes** uma de 1 XP. Se valer o dobro, ninguém a
  escolhe; se valer o triplo, todo mundo escolhe.
- **O baralho não muda ao subir de nível** (decisão do videogame). A progressão vem só de habilidades e itens.

### 12.2 Em avaliação

- **Estrutura do nível.** Quatro modelos:
  - **Linear:** todo nível dá XP e a escolha.
  - **Alternado:** ímpares dão XP; pares, a escolha.
  - **Marcos:** a escolha sempre; XP em níveis marcados.
  - **Atos:** a virada de ato entrega o grande ganho.
  - Os modelos Marcos e Atos resolvem de quebra a régua de recompensas.
- **Alteração do baralho:**
  - Modelos em análise: Fixo, Densidade, Camadas, Evolução, Crescimento e Curadoria.
  - O videogame já adotou o Fixo.
  - O Crescimento obrigaria a recalibrar toda a matemática.
- **Cartas de 3 XP:** ainda não existem em nenhuma classe.

---

## 13. O conteúdo pronto da coleção Masmorras

Os textos completos estão nas cartas. Os arquivos são listados na seção 18.

### 13.1 Classes (5)

| Classe | Estratégias (3 cartas cada) | Meia cartas (6) | Cartas de 2 XP | Metades de herói |
|---|---|---|---|---|
| **Guerreiro** | **Tanque de Guerra** (tank/aggro/control): Peso da Muralha, Ombro de Ferro, Provocar · **Mestre das Posturas** (aggro/tank/interactor): Postura do Leão, Postura da Tartaruga, Marcha Militar · **Hoplita** (escudo + lança, sinergia com Soldado): Lança em Riste, Parede de Escudos, Avanço Combinado | Respirar Fundo, Firmar os Pés, Golpe de Oportunidade, Reposicionar, Foco Marcial, Segundo Fôlego | Sangue Fervente, Âncora, Instruir Armamento | **Foco Mortal** (fura armadura) · **A Muralha** (é armadura) |
| **Ladino** | **Ladrão** (furtividade, roubo): Dedos de Seda, Ataque Furtivo, Passo de Sombra · **Malandro** (lábia, contatos): Mas Veja Bem, Finta, Rede de Contatos · **Mágico** (prestidigitação, ilusão): Truques de Salão, Mancha Sombria, Gancho Fantasma | Olho de Ladrão, Pé Ligeiro, Lâmina Rápida, Empurrão Místico, Torcer a Lâmina, Sumiço | Nunca Visto, Sempre um Plano, Passo Espectral | **Larápio** (corpo, Sombra, velocidade) · **Impostor** (blefe, contatos, trapaça) |
| **Clérigo** | **Curandeiro da Igreja**: Toque Restaurador, Feixe de Luz, Lanterna da Fé · **Exorcista**: Água Benta, Palavra de Banimento, Voz do Exorcista · **Orador Divino** (zonas e marcações): Palavra de Ânimo, Condenar, Zona da Penitência | Teologia, Primeiros Socorros, Prece Rápida, Fé Inabalável, Mão Angelical, Luz da Verdade | Ressurgir, Benção dos Salmos, Halo do Conduíte, Saltério de Cura | **Estrela do Amanhecer** (cura e sustento) · **Arma do Panteão** (abençoa o aço) |
| **Caçador** | **Mestre Arqueiro** (Mira, marcação): Preparar o Tiro, Marca do Caçador, Flecha Aleijadora · **Rastreador da Floresta** (armadilhas, óleos, iscas): Rastrear, Armadilha de Caça, Flecha Envenenada · **Caçador das Montanhas** (funda, escalada, anti‑fera): Funda Certeira, Cabra da Montanha, Flecha Pesada | Camuflagem, Tiro Rápido, Faro Aguçado, Salto de Recuo, Olho de Águia, Preparar Emboscada | Tiro Perfeito, Predador Absoluto, Tiro Mortal | **Folha de Carvalho** · **Predador da Selva** (imóvel e invisível, arma o terreno) |
| **Mago** | Uma por arquétipo, sem elemento fixo: **Conjuração Econômica**, **Poder de Combate**, **Improviso do Erudito** + 6 **Aprendizes** (Fogo, Água, Terra, Ar, Luz, Sombra) | Repertório arcano básico: Mão Mágica, Mísseis Mágicos, Contramagia, Armadura Arcana, Telepatia, Detectar Magia | Conjuração Perfeita, Mente Bélica, Mente Afiada | **Controlador do Arcano** (fôlego inesgotável, magia nas armas dos aliados) · **Devorador de Grimórios** (um caminho extra de graça, troca de foco rápida) |

**Notas sobre as classes:**
- O Clérigo tem uma carta de 2 XP a mais, Saltério de Cura, que é um repertório em forma de carta. Tem também o
  Grimório da Chama Sagrada.

### 13.2 Raças (5)

Cada raça tem 3 cartas de habilidade e 2 metades de herói.

| Raça | Cartas de habilidade | Metades de herói |
|---|---|---|
| **Humano** | Resistência do Corredor, Mente Maleável, Resposta Criativa | Incansável · Mil Ofícios |
| **Elfo** | Visão Élfica, Saber Natural, Vigília Élfica | O Atemporal (*Guardar o Instante*: agir fora da ordem dos turnos) · O Feérico |
| **Anão** | Olho para o Minério, Força das Montanhas, Filho da Pedra | O Inabalável · Palavra de Aço (mecânica de juramento) |
| **Halfling** | Sorte dos Pequenos, Passos Leves, Coragem Miúda | A Boa Estrela · Matador de Gigante |
| **Orc** | Golpe Selvagem, Fôlego Feroz, Presença Aterradora | Fúria Crescente · Brado da Horda (corrigido por economia de ações) |

### 13.3 Backgrounds (5)

Cada background tem 3 cartas (uma física, uma mental, uma social) e 2 metades de herói.

| Background | Cartas (limite de fadiga) | Metades de herói |
|---|---|---|
| **Soldado** | Vigor de Marcha (5), Olho de Veterano (2), Irmãos de Farda (2) | Ombro a Ombro · Tomar a Posição |
| **Bandido** | Mãos Leves (2), Olhar Esperto (3), Contatos do Submundo (2) | O Oportunista · Sempre uma Saída |
| **Escravo** | Couro Duro (6), Atento aos Desejos (2), Espírito Inquebrável (3) | O Sobrevivente · Trabalhador |
| **Explorador** | Fôlego de Viajante (4), Senso de Direção (2), Forasteiro Bem‑Vindo (3) | Conhecedor do Terreno · Mestre das Cavernas |
| **Fervoroso** | Resistência da Fé (3), Fé Lapidada (2), Comunidade da Fé (1) | Seguidor da Chama · Seguidor da Noite |

### 13.4 Equipamentos — 155 cartas

| Categoria | Comum | Incomum | Rara | Sem raridade |
|---|---|---|---|---|
| Armas corpo a corpo | 9 | 9 | 9 | — |
| Armas à distância | 6 | 6 | 6 | — |
| Armaduras | 3 | 3 | 3 | — |
| Escudos | 2 | 2 | 2 | — |
| Consumíveis | 10 | 5 | 5 | — |
| Permanentes | 13 | 15 | 7 | — |
| Focos arcanos / sagrados | — | — | — | 5 / 6 |
| Grimórios básicos / raros | — | — | 6 (raros) | 6 (básicos) |
| Textos Sagrados | — | — | — | 5 |
| Pedras de Runa | — | — | — | 6 |
| Amuletos | — | — | — | 6 |

**Formato:** as cartas de equipamento estão no tamanho de carta de Magic (63 × 88 mm), com 9 por página para
impressão.

---

## 14. Convenções de redação das cartas

**O texto da carta é mecânico, não de sabor.** Clareza vem antes da ambientação.

### 14.1 Leitura dos efeitos

| Termo | Significado |
|---|---|
| **"você pode"** | Opcional; serve, por exemplo, para não estourar. |
| **"+X de dano"** | Somado depois do teste; não estoura. |
| **"(conta para o limite do 21)"** | Entra no valor do teste e **pode** estourar; costuma vir com "você pode". |
| **Penalidade / Aprimoramento** | Afetam o **limite do 21** (21 → 20 / 22), não o valor do teste. |

### 14.2 Alvos

| Termo | Quem é afetado |
|---|---|
| **"aliado"** | Não inclui quem usa a carta. |
| **"você ou um aliado"** | Inclui os dois. |
| Efeito que não nomeia alvo | Afeta só quem usa a carta. |

### 14.3 Ataques

- **Nunca se escreve "ataque" solto.** A carta diz sempre "faça um ataque corpo‑a‑corpo", "faça um ataque à
  distância" ou "faça um ataque mágico".
- O tipo decide qual arma, qual atributo e quais efeitos entram.

### 14.4 Custos, termos e nomes

- **Custo:** sempre antes dos dois pontos (seção 5).
- **Oculto e desengajar:** ver os estados (seção 6.4) e o movimento (seção 3.5).
- **Nomes de deuses:** inventados, cada um com domínio concreto.

---

## 15. O que mudou no caminho

Estas são decisões que já foram revertidas. Vale saber, para não reabri‑las sem motivo.

- **Estouro.** Antes, estourar zerava o teste. Agora vale a última carta puxada, mais os modificadores.
- **Cartas com efeito no baralho — abandonadas.**
  - Antes, o baralho tinha 26 cartas com efeito, de classe, função, raça e background.
  - O playtest mostrou excesso de informação. O baralho agora é de 52 cartas comuns, e a mecânica vem só das
    habilidades.
  - As cartas de baralho que existiam ficam arquivadas, como reserva de ideias.
- **Momentum — retirado.**
  - Antes: duas ações de movimento seguidas davam embalo e movimento grátis no turno seguinte.
  - O playtest mostrou que era desnecessário e acrescentava complexidade ruim.
- **Impacto → Concussão.** O tipo de dano canônico passou a ser Concussão.
- **Fadiga no fim do turno.** Ficou definido: retira‑se só 1 ficha, de uma única carta à escolha.
- **Imobilizar.** Deixou de ser só "−1 de movimento". Agora tira a ação de Movimento e impede rebaixar Padrão até a
  carta ser virada.
- **Inimigos sem bônus de ataque e defesa.** A dureza vem de efeitos de Força e de resistência a dano.
- **Florete do Contragolpe.** A versão que garantia defesa até 25 foi descartada por apagar a linha de derrota.
- **Itens permanentes incomuns.** Foram refeitos integralmente pelo Lucas.

---

## 16. Questões em aberto

Esta é a lista do que falta para a 1.0.

### 16.1 Regras que faltam

- **Dano de queda:** o valor ainda não foi definido, e cair aparece em toda sessão.
- **Afogamento:** quantos turnos o personagem aguenta submerso.
- **Danos Graves:** os efeitos de membro quebrado, usados pela Quebra de Membro.
- **Doenças:** o subsistema. O estado já é citado por cartas.
- **Planar (voo):** citado pelo Manto do Vento, pela Runa de Ar e pelas magias de Ar.
- **Estados sem regra formal:** Queimando, Exposto, Furtividade. Cegueira precisa de efeito detalhado.
- **Ácido e Infectado:** confirmar se são persistentes.
- **Tabela de Tamanhos:** mínimo, diminuto, pequeno, médio, grande, gigante e colossal; −5 no limite por degrau. Falta
  escrever a tabela.
- **Recompensas (loot):** como o mestre distribui os itens.
- **Descansos curto e longo:** a regra completa de mesa.
- **Atributos:** redação nova para Mentira em 3 e em 5, que citam cartas com efeito. Os efeitos principais de
  Percepção e Mentira ainda têm pouco uso.

### 16.2 Varreduras de consistência

- **Tag de velocidade** (lenta/rápida) em todas as magias e itens.
- **"No limite":** cartas que dizem "−1/+1 no próximo teste" devem falar em **limite do 21**.
- **Atributo dos Textos Sagrados:** Espírito ou Sabedoria.
- **Faixas de dificuldade:** recalibrar com a regra nova de estouro.
- **Fichas:** listar todos os usos de Foco e Sombra no glossário.
- **Cartas de equipamento:** 34 ainda sem a moeda de raridade e 9 com texto antigo.

### 16.3 Conteúdo

- **Cartas de 3 XP:** nenhuma classe tem.
- **Estrutura do nível e alteração do baralho:** ver a seção 12.2.

### 16.4 Playtest

- **Efeito exato do crítico.**
- **Teto do 21** com todos os somadores.
- **Quantidade de fichas em jogo.**
- **Dados de dano:**
  - O primeiro playtest mostrou que um grupo de 5 heróis de nível 1 causa cerca de **45 de dano por turno**.
  - Cada jogador causa de 10 a 20, usando todas as ações.
  - Estima‑se cerca de 60 no nível 2.
  - Falta medir como o dano cresce por nível.

### 16.5 Fora da 1.0 (v2.0)

- **Classe Senhor da Guerra** (o comandante).
- **Encantamento e ferraria.**
- **Itens de acesso rápido.**
- **Focos incomuns e raros.**
- **Próximas coleções.**

---

## 17. O videogame (projeto paralelo)

O Sistema 21 está sendo adaptado para videogame. As regras podem mudar para caber no computador, desde que o núcleo
fique. As decisões detalhadas de cada versão ficam no repositório.

### 17.1 Formato

- **Plataforma e venda:** PC, pago na compra, com expansões de história depois.
- **Gênero:** RPG tático isométrico por turnos, com grupo de 3 a 6 heróis. A dificuldade escala com o tamanho do
  grupo.
- **Sem mestre:** a história é pré‑definida, focada em exploração, combate e narrativa.
- **Modos de jogo:**
  - solo, controlando o grupo todo;
  - tela dividida local;
  - multijogador online.
- **Testes:** todos manuais.
- **Desenvolvimento:**
  - O jogo é feito em Godot pelo Claude.
  - O Lucas tem modelos 3D próprios, cinzas.
  - A arte está em aberto; primeiro vem o protótipo.

### 17.2 Mundo e campanha

- **Ambientação:** fantasia sombria numa terra devastada, no estilo de The Witcher 3.
  - Os heróis são de uma **Guilda de aventureiros** que faz missões por dinheiro para melhorar a região.
  - Há problemas em escala local, média e continental.
- **Três problemas continentais fixos,** que os heróis não resolvem:
  - **Praga da Fome**;
  - **Região Eldritch**;
  - **Marcha da Morte**, um exército de monges que prega a morte.
- **Campanha:** 4 ciclos de 3 missões.
  - A 1ª missão abre a trama, a 2ª desenvolve e aponta o problema final, a 3ª resolve.
  - O grupo sobe de nível a cada ciclo, do 1 ao 5.
  - Missões desbloqueiam outras missões.
  - Cada missão tem muitos pontos de interação: lore, itens, pequenas vantagens.
- **Descanso e save:**
  - Descanso curto só em pontos específicos da missão; descanso longo só em acampamentos e tavernas.
  - Salvar só nos pontos de descanso curto, liberados quando não há inimigos por perto.
- **O baralho nunca muda.** A progressão vem de habilidades e itens.

### 17.3 Valores provisórios no jogo

Estes números ainda estão sob decisão do Lucas.
- **XP:** +2 por nível; 2 no nível 1, 10 no nível 5.
- **Inimigos:** +25% de vida e +1 de dano por nível acima do 1.
- **Fichas:** cada carta guarda no máximo uma ficha de cada tipo, exceto fadiga (e Fúria); quem recebe a mais sem
  carta livre perde a ficha. Os inimigos não têm esse limite.
- **Metas de equilíbrio dos combates:**
  - Lutas simples custam de 35% a 45% da vida do grupo.
  - Um elite é perdível de 25% a 40% das vezes sem estratégia e vencível cerca de 75% com habilidade.
  - Um chefe é quase invencível sem estratégia (cerca de 10% de vitória) e cerca de 50% com estratégia moderada.

---

## 18. Arquivos de referência

| Arquivo | Conteúdo |
|---|---|
| `SISTEMA_21_Livro_de_Regras_0.5.md` | O livro de regras completo, base deste resumo. As seções sobre cartas de baralho e Momentum estão desatualizadas. |
| `Manual_de_Mesa.pdf` | 6 folhas de consulta rápida: ações, fichas, teste e combate, estados e tipos de dano. |
| `SISTEMA_21_Cartas_Oficial.xlsx` | Todas as cartas de classe, raça e background com texto completo, mais armas, itens e perícias. |
| `Habilidades_Cartas.pdf` | Cartas de habilidade das classes, raças e backgrounds, para impressão. |
| `Herois_Cartas.pdf` | Metades de herói, para impressão. |
| `Racas_Backgrounds_Cartas.pdf` | Cartas de raça e background, para impressão. |
| `Equipamentos_Cartas.pdf` | As 155 cartas de equipamento (63 × 88 mm, 9 por página). |
| `Modelos_Passagem_de_Nivel.md` | Os modelos de progressão em avaliação. |
| `cartas/3_Filosofia_de_Game_Design.md` | A filosofia de design por extenso. |
