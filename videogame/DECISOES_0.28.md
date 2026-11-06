# Sistema 21 — versão 0.28: monstros clássicos e seis missões prontas

As seis missões foram feitas como **fases do editor**. Elas aparecem na biblioteca do editor como `[exemplo]`, no menu (Jogar fase), na sala de rede e no **mural da campanha**, na seção "Outros contratos". Para mudar alguma, abra no editor e use **Duplicar**: a cópia é sua e pode ser alterada à vontade.

## 1. Monstros novos (27 no bestiário do editor)

| Monstro | Patamar | O que faz |
|---|---|---|
| Rato Gigante | lacaio | Rápido; a mordida dá Veneno |
| Lobo | lacaio | Matilha: quando um acerta, outro avança |
| Lobo Atroz | médio | Salta em quem o feriu e derruba |
| Aranha Gigante | médio | Teia (Imobilizar) e veneno |
| Escorpião Gigante | médio | Carapaça dura, ferrão venenoso |
| Zumbi | lacaio | Lento e agarra. Levanta de novo, a não ser que caia por fogo, luz ou concussão |
| Zumbi Inchado | médio | Ao cair, estoura e dá dano e Veneno em quem estiver do lado |
| Carniçal | médio | Rápido; as garras imobilizam |
| Múmia | médio | Lenta e resistente; dá Medo; fraca contra Fogo |
| Bandido / Bandido Besteiro / Capanga | lacaio / médio / médio | Faca que foge sozinho / atira e recua / guarda-costas |
| Capitão dos Bandidos | elite escoltado | Grita ordens e varre em arco |
| Cultista | conjurador | Medo e ataque à distância |
| Guarda Corrupto | médio | Lança e escudo |
| Assassino Mascarado | médio | Rápido, causa Sangramento |
| Duelista Mascarado | elite escoltado | Salta para longe quando cercado (teleporte) |
| Orc Saqueador | médio | Fica mais perigoso quando ferido |
| Ogro | elite | Pancada no chão que derruba em volta |
| **Troll** | elite | **Regenera 6 por turno**, a não ser que esteja com ficha de Fogo. Também é fraco contra Ácido |
| Gárgula / Armadura Animada | médio | Duros contra lâminas; fracos contra concussão e raio |
| Elemental do Fogo / da Terra | médio | Queima e explode em brasas / lento e revida |
| Diabrete | lacaio | Voa, cospe fogo e foge de quem chega perto |
| **Verme da Areia** | chefe | Mergulha na areia e surge longe; o bote derruba em área |
| **Vaelor, o Mago da Torre** | chefe | **Invoca** um Elemental do Fogo ou um Diabrete a cada 3 turnos (até 2 vivos), teleporta, Bola de Fogo, Lentidão e Confusão |

Os modelos 3D são os modelos que o jogo já tinha, em outras cores e tamanhos. Lobos, ratos, aranhas, escorpiões e o verme são peças novas feitas de formas simples.

### Mecânicas novas no motor
- **Regenerar** (habilidade de chefe/elite): cura no começo do turno; a ficha de Fogo impede.
- **Invocar**: a criatura surge perto do invocador, já alerta, e age logo depois dele. **Se o invocador cair, todas as invocações somem.** A vida da invocação acompanha o tamanho do grupo, como a dos outros monstros.
- **Pistas** (para investigação): um efeito novo, "Pista", anota uma pista com nome. Uma opção pode exigir "Precisa de quantas pistas", e enquanto o grupo não tiver o número pedido, a opção aparece bloqueada com a mensagem "faltam pistas (vocês têm X de Y)". Duas formas de achar a mesma pista contam como uma só. As pistas valem só durante aquela fase.
- **Dinheiro negativo** num efeito agora aparece como "o grupo paga X pratas" (suborno, aposta perdida).

## 2. As seis missões

| Missão | Tipo | Nível sugerido | Abre depois de | Pagamento |
|---|---|---|---|---|
| Vau-Cinzento: o poço envenenado | Investigação urbana | 1–2 | Fazenda | 150 |
| Os Sinos Mudos: o bairro dos mortos | Limpar zumbis (noite) | 2 | Cripta | 200 |
| O Bairro do Cão Vermelho | Invasão de território de bandidos | 2–3 | Vau-Cinzento | 220 |
| O Baile das Máscaras de Prata | Social / roleplay | 3 | Cão Vermelho | 250 |
| As Areias de Kesh-Tar | Deserto aberto | 3–4 | Pântano | 280 |
| A Torre de Vaelor | Torre do mago (4 andares) | 4–5 | Kesh-Tar | 350 |

Há um fio de história leve ligando as missões: o **Círculo Rubro** aparece no recibo do capitão Orsk, na carta do baú de Ferrabrás e na carta do Barão Corvin. O livro do coveiro Hesk veio da torre, e o grimório de Vaelor lista o Círculo Rubro entre os compradores. Isso deixa um gancho pronto para uma missão futura contra o Círculo.

### Vau-Cinzento (investigação)
Três mortos depois de beber do poço. O grupo conversa e examina a cidade para juntar **3 pistas**:
- o poço (Investigação ou Medicina);
- o boticário (Intuição ou Intimidação);
- a viúva (Acalmar);
- o taverneiro (Jogatina ou Negociação);
- o baú trancado do posto da guarda (Ladinagem ou pé de cabra). Se falhar, os guardas do cais vêm.

Com 3 pistas, a porta do armazém abre e o grupo enfrenta o Capitão Orsk com os cultistas e os ratos. Sem pistas, dá para arrombar a porta (teste difícil). Objetivo: derrotar Orsk.

### Os Sinos Mudos (zumbis)
Noite escura com três setores, cada um com seu grupo:
- a rua, com zumbis dormindo e um inchado;
- os becos, com carniçais;
- o cemitério com a capela, onde está **Hesk, o Coveiro** com um carniçal.

Para ajudar:
- os barris de óleo dão frascos de piche e tochas;
- os sobreviventes da janela dão água abençoada (Acalmar);
- a corda do sino da capela, se for tocada, dá Foco ao grupo.

A barricada do meio pode ser desmontada (turno inteiro, faz barulho e acorda o cemitério) ou pulada (Atletismo). Objetivo: derrotar todos.

### O Cão Vermelho (bandidos)
Há três caminhos:
- **o portão**: arrombar ou abrir com gazua;
- **o esgoto**: corredor fechado de terreno difícil que sai dentro do curtume. Teste de Furtividade na entrada; se falhar, o curtume fica alerta;
- **o informante**: um garoto que, por 10 pratas, abre uma porta no muro do beco.

Besteiros ficam **nos telhados** (nível 1, com escadas) e veem longe. Reféns no depósito dão dinheiro e dicas depois que a área fica sem inimigos. No curtume há tonéis de óleo para incendiar e o baú do capitão. Objetivo: derrotar o Capitão Ferrabrás.

### O Baile das Máscaras de Prata (social)
**Enredo:** um bilhete anônimo avisa que a Duquesa Lisandra vai morrer no brinde da meia-noite. O culpado é o **Barão Corvin**: ele perdeu as terras para ela no tribunal, está falido e o Círculo Rubro prometeu devolvê-las. O veneno vai na taça azul, e ele trouxe assassinos disfarçados de criados.

Convidados e o que cada um exige:
| Convidado | Teste |
|---|---|
| Duquesa | Nobreza |
| Mordomo | Intuição |
| Barão de máscara de corvo | Atuação + Mentira, ou Irritar |
| Poeta bêbado | Arte |
| Dama de vermelho | Jogatina, com aposta |
| Capitão da guarda | Liderança |
| Quarteto de cordas | Arte, dá Foco |
| Roda de fofoca | Política |
| Garrafa na adega | Investigação |

Com **3 pistas**, "Interromper o brinde e desmascarar o Barão" libera. A luta começa: o Barão (Duelista) e 3 assassinos saem da varanda e do corredor de serviço. **Acusar a pessoa errada** (o mordomo ou a dama) não trava a missão: só dá Penalidade e um texto de constrangimento. Objetivo: derrotar o Barão.

### As Areias de Kesh-Tar (deserto)
Mapa de **60×48** com borda irregular de "vazio". Com a névoa, o grupo não sabe até onde o deserto vai. Pontos espalhados:
- **o oásis**: água, tâmaras e descanso;
- **rastros** (falas) que levam à caravana;
- **sol a pino**: teste de Sobrevivência; se falhar, dá dano;
- **miragem**;
- **areia movediça**: armadilha que Imobiliza;
- **escorpiões**;
- **acampamento de saqueadores**: o chefe deixa um mapa;
- **templo** com múmias dormindo e um sarcófago que ensina a fraqueza do verme;
- **a caravana** guardada pelo **Verme da Areia**.

Objetivo: desenterrar o cofre e pegar o Selo de Kesh. Só dá para fazer isso **sem inimigos alertas**, então na prática é preciso vencer o verme.

### A Torre de Vaelor
Quatro andares, cada um uma sala num nível mais alto, ligados por escadas:
- **Térreo**: duas armaduras animadas, uma runa de fogo no piso (armadilha) e uma porta selada. Para abrir: Arcanismo, ou forçar (teste difícil, com dano).
- **Biblioteca**: gárgulas dormindo, piso falso (Acrobacia; se falhar, dano e Sangramento) e anotações. As anotações contam que as invocações somem se Vaelor cair e dão um Pergaminho do Desencantamento.
- **Laboratório**: elementais e diabretes. O **círculo de invocação** pode ser quebrado (Arcanismo + Espírito), e isso desfaz todo o laboratório.
- **Observatório**: Vaelor, com uma armadura, invocando reforços.

Há pontos de descanso no térreo e no laboratório. Objetivo: derrotar Vaelor. O saque inclui o Anel do Iniciado e uma Poção de Amplificação.

## 3. Como foi verificado
- **Testes:** 300 testes automáticos e 0 falhas. A versão 0.28 traz 8 testes novos:
  - todos os monstros entram em batalha;
  - o troll regenera, mas não com Fogo;
  - Vaelor invoca, e as invocações somem quando ele cai;
  - as pistas liberam a opção certa;
  - cada missão passa na validação do editor e aparece no mural;
  - em cada missão, todo inimigo e toda interação podem ser alcançados a partir do início, depois de abertas as portas;
  - o robô joga um trecho de cada missão com todos alertas, e Vaelor invoca de verdade.
- **Capturas:** as 6 missões foram vistas no editor e no jogo 3D, mais uma vitrine com os 27 monstros juntos.

## 4. Para você decidir
1. **Dificuldade.** Os números dos monstros saem da calibragem automática por patamar, pensada para 4 heróis. O Ogro, por exemplo, ficou com 146 de vida para 4 heróis. Jogue uma das missões e me diga se algum monstro ficou forte ou fraco demais; dá para ajustar o patamar ou usar "números próprios" no editor.
2. **Pistas entre missões.** Hoje as pistas valem só dentro da fase. Quer que algumas fiquem guardadas na campanha (por exemplo, para uma missão final contra o Círculo Rubro)?
3. **Acusação errada no baile.** Hoje ela só dá Penalidade. Prefere que ela tenha uma consequência mais forte, como a Duquesa expulsar o grupo (derrota) ou os assassinos atacarem antes da hora?
4. **O tamanho do deserto.** O mapa tem 60×48, o máximo do editor é 60×60 e ainda está tudo numa única tela de batalha. Quer um deserto "de verdade" em várias partes (sair por uma borda leva a outro mapa)? Isso exigiria um sistema de mapas encadeados.
5. **Missão contra o Círculo Rubro.** Quer que eu faça a missão que fecha esse fio de história numa próxima versão?
