# Versão 0.26 — jogo em rede (mesmo Wi-Fi, cabo ou Hamachi)

Agora dá para jogar com até 4 pessoas, cada uma no seu computador. Funcionam as missões avulsas e a campanha completa: vila andável, lojas, estalagem e mural.

Do jeito que você pediu:

- **Cada um traz o seu herói.** Cada jogador escolhe um herói salvo no próprio computador e joga só os turnos dele.
- **Campanha em party.** O anfitrião cria a party e os jogadores vinculam os seus heróis a ela. A party fica salva no computador do anfitrião, e a campanha sempre segue o computador dele.

## Como jogar

1. **Todos precisam da mesma versão** (0.26). O jogo confere e avisa se for diferente.
2. **Mesmo Wi-Fi ou cabo:**
   - O anfitrião abre **Jogar em rede → Criar a sala**.
   - A tela mostra os endereços dele; o que serve é o que começa com **192.168.** (ou **10.**).
   - Os outros abrem **Jogar em rede**, digitam esse endereço e clicam em **Entrar**.
3. **Hamachi:**
   - Todos entram na mesma rede do Hamachi.
   - O anfitrião cria a sala e passa o endereço **25.x.x.x**: é o que o Hamachi mostra ao lado do nome do computador dele, e a sala também mostra.
   - Os outros digitam esse endereço.
4. **Firewall do Windows:** na primeira vez, o Windows pergunta se o Sistema 21 pode usar a rede.
   - Marque **Redes privadas** e clique em **Permitir**. No anfitrião isso é obrigatório.
   - No Hamachi, se a rede dele estiver como "pública", marque também **Redes públicas**.
   - Se alguém não conseguir entrar, quase sempre é isso.
5. **Porta:** o jogo usa a porta **7021**. Na mesma rede e no Hamachi não é preciso mexer no roteador.

## Na sala

1. **Seu nome:** cada jogador escreve o seu. O jogo lembra o nome e o último endereço digitado.
2. **O anfitrião escolhe a partida:**
   - **Missão avulsa:** arena, fazenda, cripta, pântano, catacumbas, trilha ou X1. O treino é só para um jogador.
   - **Campanha em party:** escolhe uma party salva ou cria uma nova, dando um nome.
3. **Heróis na missão avulsa:**
   - Cada jogador clica em **Levar** num herói do próprio computador.
   - A ficha vai para o anfitrião só durante a partida. Nada muda no computador de ninguém.
4. **Heróis na campanha:**
   - **Na primeira vez**, cada jogador clica em **Vincular** num herói do computador dele. A ficha é copiada para a party, no anfitrião, e daí em diante é essa cópia que evolui (XP, compras, feridas).
   - **Nas vezes seguintes**, cada um clica em **Jogar com este** no herói dele, na lista da party.
   - O anfitrião pode **tirar** um herói da party. Isso só vale para quem não está na sala com ele escolhido.
5. **Limites:**
   - O grupo tem até 4 heróis.
   - Cada convidado leva 1 herói.
   - O anfitrião pode levar mais de um, para completar o grupo.
   - Nomes de heróis repetidos não entram: o jogo avisa.
6. **Começar:** só o anfitrião começa. O botão explica o que falta (por exemplo, "Bia ainda não escolheu o herói").

## Na batalha e na vila

1. **De quem é a vez:** a faixa no alto diz "Sua vez: Lume" ou "Vez de Brom (Ana)".
   - Só o dono do herói da vez clica.
   - Se outro jogador clicar, aparece um aviso de quem decide.
2. **Quem decide cada momento** (quem não decide não vê essas janelas):

   | Momento | Quem decide |
   |---|---|
   | Turno, ataques e perícias | o dono do herói da vez |
   | Defesa quando um monstro ataca | o dono do herói atacado. Ele puxa ou para, e reparte o dano entre escudo e armadura |
   | Guarda e A Muralha | o dono do herói que protege |
   | Golpe de Oportunidade, Castigo e reações | o dono de quem reage |
   | Sombra | o dono do herói escolhido como alvo |
   | Fichas ganhas (em qual carta fica) | o dono do herói |
   | Planejar, Scry e Foco Marcial | o dono do herói, e só ele vê as cartas do topo |

3. **Monstros:** o computador do anfitrião joga os monstros, e todos veem.
4. **Vila:** em rede, **todo o grupo anda pela vila**, em turnos, como numa missão (sozinho, só o líder anda).
   - Quem entra num prédio vê a loja na tela dele. Os outros recebem um aviso ("Lume entrou: mercado").
   - **Compras e vendas:** cada jogador compra e vende **para o próprio herói**, com a bolsa do grupo.
   - O pedido vai ao anfitrião, que salva e manda a bolsa e as fichas novas para todos.
   - **Estalagem:** qualquer jogador pode pagar o descanso do grupo.
   - **Mural:** todos veem os contratos, mas **só o anfitrião clica em Partir**. Quando ele parte, todo mundo vai para a missão junto.
5. **Fim da missão:**
   - O anfitrião registra a campanha: pagamento, XP, feridas e encomendas.
   - Todos veem o mesmo resumo.
   - Só o anfitrião escolhe o que vem agora: voltar à vila (na campanha), jogar de novo ou voltar para a sala (na missão avulsa).
6. **Salvar:**
   - Em rede não há os 3 espaços de salvamento.
   - A party se salva sozinha no computador do anfitrião, a cada compra, venda, estalagem e fim de missão.
7. **Menu (Esc):**
   - O anfitrião tem **Levar todos de volta para a sala** e, na campanha, **Desistir da missão e voltar à vila**.
   - Qualquer um pode **Sair da partida em rede**.

## Quedas de conexão

1. **Se um convidado cai**, o anfitrião passa a controlar os heróis dele.
   - Para voltar, o convidado entra de novo na sala com **o mesmo nome**.
   - Ele cai direto na partida em andamento, no ponto em que ela está, com os heróis dele de volta.
2. **Se o anfitrião sai ou cai**, a partida acaba para todos. Os convidados voltam para a sala com um aviso.
   - Na campanha, o que já foi salvo continua salvo no anfitrião: compras, vendas e fins de missão.
3. **Se algum computador sair de sincronia**, ele pede o estado ao anfitrião e continua dali sozinho.
   - Aparece "Sincronizando com o anfitrião…" por um instante.
   - Isso não deve acontecer, mas fica como rede de segurança.

## Para você decidir

1. **Vila em turnos:** em rede, todos andam pela vila em turnos (cada um espera a vez do outro). Prefere assim, ou que a vila tenha movimento livre para todos ao mesmo tempo? (Dá mais trabalho, porque a vila hoje usa a mesma regra de turnos das missões.)
2. **Compras só para o próprio herói:** a bolsa é do grupo, mas cada jogador só compra e vende para o herói dele. Quer deixar qualquer jogador comprar para qualquer herói?
3. **Só o anfitrião parte para a missão.** Prefere uma votação, ou que qualquer jogador possa partir?
4. **Salvar no meio da missão em rede:** hoje não dá; a party guarda o progresso entre missões. Quer o salvamento nos pontos de descanso também em rede (o anfitrião salva e, ao reabrir a party, todos voltam ao mesmo ponto)?
5. **Defesa automática e "sempre usar a sugestão" do dano:** em rede valem as opções do anfitrião para todos (as de cada convidado ficam travadas). Quer que cada jogador escolha as suas, só para os próprios heróis?
6. **Reações contra magia** (Contramagia, Roubo Arcano, Mana Densa): a pergunta aparece para o dono do alvo e para os donos de quem pode reagir, cada um com as suas opções. Se o dono do alvo clicar em "Deixar a magia acontecer" primeiro, a pergunta fecha para todos. Está bom, ou prefere esperar todos responderem?
7. **Missão avulsa não muda o herói:** XP e itens ganhos numa missão avulsa em rede não voltam para o herói de ninguém (igual à missão avulsa sozinho). Está certo?
8. **Herói vinculado é uma cópia:** depois de vincular, o herói da party e o do computador do jogador seguem separados. Quer um botão para o jogador trazer de volta para o computador dele a versão da party?
9. **Até 4 heróis e 4 jogadores**, como no jogo sozinho. O plano fala em 3 a 6 personagens: quer liberar 5 e 6 em rede?

## Testes

- **Testes novos**:
  - duas batalhas montadas do mesmo retrato, recebendo os mesmos comandos, terminam idênticas: arena com Bruxo, fazenda e cripta com 4 heróis;
  - quem decide cada momento;
  - a party salva no anfitrião (criar, vincular, comprar, reabrir, desvincular, apagar);
  - a campanha na memória dos convidados.
- **Teste com dois jogos abertos de verdade, em rede**, no mesmo computador:
  - **missão avulsa:** os dois terminam no mesmo estado depois de 89 comandos;
  - **campanha:** party nova, os dois heróis andando na vila, uma compra da convidada pelo anfitrião, partida para a fazenda e estados idênticos no fim;
  - **ressincronização:** estraguei de propósito o estado da convidada; ela percebeu, pediu o estado e terminou igual ao anfitrião;
  - **queda e volta:** fechei o jogo da convidada no meio da fazenda. O anfitrião assumiu o herói dela; ela entrou de novo com o mesmo nome, voltou para a mesma partida e terminou no mesmo estado.
- **Total:** 283 testes, 0 falhas.
