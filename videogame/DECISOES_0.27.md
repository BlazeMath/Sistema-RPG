# Versão 0.27 — Editor de fases

Agora dá para montar fases sem programar. No menu, escolha **Editor de fases e fases criadas**.

O mapa é editado em 2D, visto de cima. O botão **Testar no jogo** abre a fase no jogo de verdade, em 3D, com o grupo de heróis atual. No fim do teste, **Voltar ao editor** traz você de volta para a mesma fase.

## Como usar

Escolha a ferramenta na esquerda e clique no mapa. O painel da direita mostra o que está selecionado, e é nele que você edita os detalhes.

| Ferramenta | O que faz |
|---|---|
| **Selecionar** | Clique para ver e editar. Arraste um inimigo, interação, luz, objeto ou início para mudar de lugar. Delete apaga. |
| **Chão** | Grama, pedra, lodo, terra, madeira, areia, água (só quem nada atravessa), terreno difícil (custa 2) e **Vazio** (a casa não existe: é o formato do mapa). Shift + arrastar faz um retângulo; Ctrl + clique faz um balde. |
| **Altura** | Andares (−1 a 2) e escadas, como nas Catacumbas. |
| **Objetos** | 35 objetos (parede, porta, pilar, árvore, baú, mesa, fogueira...). Antes de pôr, escolha **Colisão** (bloqueia o passo ou não) e **Visão** (como o objeto, bloqueia ou não bloqueia). Objeto sem colisão vira enfeite. Fogueira, tocha, lanterna e velas iluminam sozinhas. |
| **Luz** | Fonte de luz com raio claro e de penumbra, para fases escuras. |
| **Início** | Onde cada herói começa (1 = primeiro do grupo). Se faltar lugar, o herói começa na casa livre mais perto. |
| **Inimigos** | Escolha no bestiário e clique no mapa. Ajustes estão logo abaixo. |
| **Áreas** | Crie uma área e pinte as casas dela (o botão direito apaga casas da área). Os tipos estão logo abaixo. |
| **Interação** | Ponha um ponto (baú, livro, porta, pessoa) e crie as opções e os efeitos no painel. |
| **Borracha** | Apaga o que estiver na casa, um item por clique. |

O mapa tem zoom na roda do mouse e se arrasta com o botão do meio ou o direito. Ctrl+Z desfaz, Ctrl+Y refaz e Ctrl+S salva.

**Inimigos.** São 15 do bestiário: os goblins, o Chefe Goblin, a Toupeira, os esqueletos, Sir Aldric, Vel-Dorath, o afogado, o fantasma, a Bruxa Morgana e o boneco.
- **Ajustes:** nome, patamar, papel, grupo, se já começa alerta, se está dormindo, até onde vigia e se é **alvo do objetivo** (★).
- **Números calculados:** o painel mostra vida, dano, resistência e velocidade calculados para 4 heróis.
- **Números próprios:** com essa caixa marcada, você escreve vida (pensada para 4 heróis; muda 30% por herói), dano, resistência, velocidade, ataques por turno, ataque à distância, ataque de oportunidade, tamanho, categoria, tipo de dano, visão no escuro, jeito de puxar cartas e fraquezas/resistências por tipo de dano (+ fraqueza, − resistência).
- **Saque:** efeitos que ele deixa ao cair. Vira um ponto "Saque" no chão; pegar custa 1 Movimento.

**Tipos de área:**
- **Fala:** texto ao entrar. Pode oferecer "procurar armadilhas".
- **Teste:** pede um teste ao entrar, com perícia, atributo e dificuldade. Cada resultado (passou ou falhou) tem texto e efeitos.
- **Acontecimento:** efeitos ao entrar.
- **Armadilha:** dano, ficha e dificuldade de achar, escapar e desarmar.
- **Chegada:** cumpre a fase.

**Interações.** Cada opção tem:
- texto, custo (nenhum, Movimento, Padrão ou o turno inteiro) e "só uma vez";
- "só sem inimigos alertas", item exigido e classes;
- um teste (opcional), com perícia, atributo e dificuldade;
- texto e efeitos para cada resultado.

O ponto pode ser **escondido**: aparece quando alguém procura.

**Efeitos disponíveis:** dinheiro (pratas), item, dano, ficha no herói, ficha para o grupo, tirar fadiga, descanso curto, fala, história (registro), alertar um grupo, inimigos vão embora, marcar inimigo, **abrir caminho** (você escolhe as casas no mapa), ativar outra interação, desativar esta, queda, abrir missão no mural e **vitória**.

**Propriedades da fase** (botão no alto):
- nome, descrição, tamanho (até 60×60), piso padrão e fase escura ou noite com lua;
- texto de abertura;
- **objetivo:** derrotar todos, derrotar os alvos, chegar a uma área, cumprir uma interação ou sobreviver N rodadas;
- mensagem de vitória e grupos de inimigos, com o texto de quando são avistados;
- **campanha**, explicada abaixo.

**Validar** lista os problemas da fase: início bloqueado, inimigo fora do chão, objetivo sem alvo, efeito sem item... Clicar num problema seleciona a coisa. O Testar avisa se houver problemas, mas deixa testar mesmo assim.

## Biblioteca

- **Onde ficam:** as fases são salvas na pasta das fases do jogo; o botão **Abrir a pasta das fases** mostra onde. Cada fase é um arquivo `.json`, então dá para mandar a um amigo, e ele põe na pasta dele.
- **Botões:** Editar, Jogar (com o grupo atual), Duplicar, Apagar (pede confirmação) e Nova fase.
- **Exemplo:** vem pronta a fase **"Exemplo: o moinho do rio"**. Ela usa rio com ponte, quintal com goblins, chefe no moinho, armadilha, teste na ponte, poço de descanso, livro de lore e saque. Exemplos não se apagam; ao salvar, vira uma cópia sua.

## Campanha e jogo em rede

- **No mural:** em **Campanha** (nas propriedades da fase), marque **Aparece no mural**. Escolha o texto do contrato, o pagamento, o ciclo (0 = "Outros contratos") e quais missões precisam estar terminadas antes. Na vila, a fase aparece no quadro como qualquer missão.
- **Em rede:**
  - na sala, as fases criadas pelo anfitrião entram na lista de missões avulsas;
  - na campanha em party, as fases do mural do anfitrião aparecem para todos;
  - o anfitrião manda a fase junto: os convidados não precisam ter o arquivo.

## Mudanças no motor

- **Chão:** pode ser escolhido casa a casa. As casas **vazias** não têm chão nem a base de madeira, bloqueiam o passo e não bloqueiam a visão.
- **Objetos:** cada um pode ter colisão e visão próprias.
- **Saque:** um inimigo com saque deixa um ponto de interação no chão ao cair.
- **Áreas:** uma área pode pedir um teste ou fazer efeitos acontecerem quando um herói entra, com a mesma mesa de teste das armadilhas.
- **Objetivo novo:** sobreviver N rodadas (a vitória vem quando a rodada N termina).

## Para você decidir

1. **Saque:** pegar o saque custa 1 Movimento e fica no chão até alguém pegar. Prefere que o dinheiro do saque vá direto para o grupo, sem precisar pegar?
2. **Chegada:** basta **um** herói entrar na área. Quer a opção "todos os heróis precisam chegar"?
3. **Fase do mural e nível do grupo:** as fases do editor no mural pagam e contam como missão feita, mas **não** contam para fechar um ciclo e subir de nível (isso continua com as missões do ciclo). Quer que contem?
4. **Números próprios:** a vida escrita vale para 4 heróis e muda 30% por herói, como a calibragem. Prefere que a vida seja fixa, igual para qualquer grupo?
5. **Monstros novos no bestiário:** hoje o bestiário tem os 15 monstros das missões, e os números próprios mudam os valores, mas não dão habilidades novas (reações, magias, ações de chefe). Quer um editor de habilidades de monstro numa próxima versão?
6. **Diálogos com escolhas:** uma interação já pode ter várias opções (cada uma é uma "fala" do herói, com teste ou não). Quer conversas em árvore (uma resposta abre novas opções)? Dá para fazer com "ativar outra interação", mas uma árvore própria seria mais confortável.

## Testes

- **Testes novos:** conversão do chão (vazio, água, terreno difícil, pedra), objetos com e sem colisão e visão, início, inimigos do bestiário (os 15 montam), números próprios e fraquezas, saque, as áreas de fala, teste e armadilha, interações com e sem teste, os 4 objetivos, validação, biblioteca (salvar, ler, duplicar, apagar) e fase no mural.
- **Editor de verdade, com um robô:** pintou chão com balde, fez paredes com retângulo, desfez e refez, pôs inimigo, área de chegada e interação com efeito, validou sem problemas, salvou e a batalha montou.
- **Rede:** dois jogos jogando a fase de exemplo terminaram no mesmo estado depois de 105 comandos.
- **Total:** 291 testes, 0 falhas.
