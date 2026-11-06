# Versão 0.25 — equipamentos, economia, inventário, Bruxo e revisão das habilidades

Tudo dos cinco documentos entrou nesta versão. Onde o documento deixava algo em aberto, ou o jogo ainda não tem o sistema necessário, escolhi a leitura mais simples e listei abaixo, em "Para você decidir".

## 1. Os 170 equipamentos

1. **Todos os 170 itens estão no jogo**, com os mesmos nomes, números e textos das cartas (EQ-001 a EQ-170).
   - Os dados vêm do estudo de economia e da tabela do inventário: preço, loja, revenda e espaço.
   - O arquivo fica em `data/equipamentos.json` e é gerado por `tools/gerar_equipamentos.py`.
2. **Dano das armas**: vale o dano das cartas (faca 2, espada longa 4...).
   - O ajuste de **+1 nas armas leves**, pedido na 0.13, continua por cima. A faca fica com 3.
   - O Arco de Guerra virou **Arco Longo**, como na carta. Heróis antigos são convertidos sozinhos.
3. **Na criação** aparecem:
   - os itens **comuns**;
   - os **focos** da classe;
   - os **grimórios básicos e textos sagrados**, como "conjunto inicial" dos conjuradores, como o estudo sugere.
   - Os outros itens se compram na vila. Os que o herói já tem também aparecem, para a ficha não perdê-los.
4. **Sem arma**: novo item "Sem arma (desarmado)", para o conjurador que leva só foco e livros.
5. **Itens com ativada viram cartas na batalha** (com o limite de fadiga do item):
   - acessórios e amuletos;
   - as Grevas do Vazio;
   - o Montante de Batalha, a Lança Trovejante e a Francisca;
   - cada grimório ou texto sagrado.
6. **Grimórios e textos sagrados**:
   - Cada livro carregado vira uma carta com uma opção por magia, como os repertórios.
   - As magias pagam fadiga como **Conjuração**: em qualquer carta com espaço.
   - Atributo das magias, pelo livro de regras: **Raciocínio** nos grimórios e **Espírito** nos textos sagrados.
   - Requisitos:
     - grimório: a tag elemental, que vem das cartas de Aprendiz ou de um pacto do Bruxo;
     - texto sagrado: ser Clérigo.

### O que já funciona na batalha
- **Armas**:
  - Estilete: o crítico ignora resistência.
  - Florete de Duelista: reação de contra-ataque.
  - Chicote: puxa 1; se não der, o alvo não se afasta.
  - Francisca: arremesso a até 3 quadrados; volta no próximo turno.
  - Espada do Mestre-Ferreiro: +1 no limite.
  - Alabarda: empurra 1.
  - Maça-Estrela: Ferimento.
  - Machado Barbado: 2 de dano no inimigo ao lado.
  - Montante de Batalha: ataque em área.
  - Adaga da Mão Vazia: dano extra e descarte.
  - Florete do Contragolpe: dano ao vencer a defesa por 5; sem armadura nem escudo.
  - Cajado do Condutor: magias mais baratas.
  - Lâmina do Vento: +1 de Velocidade.
  - Gládio Inquietante: vira as cartas.
  - Lança da Muralha: Imobilizar em si.
  - Quebra-Elmos: ignora resistência; sem Reação.
  - Machado da Sepultura: exila figuras para dano; cura pela metade.
  - Adaga Balanceada: devolve a ficha de Foco.
  - Machete Farpado: Sangramento.
  - Lança Espiral: fadiga vira dano.
  - Arco de Teixo: dobro contra marcado.
  - Besta da Seta Dupla: dano no inimigo ao lado.
  - Machado Sedento: dano pelas figuras do descarte; tritura 1 carta.
  - Lança Trovejante: área de Raio e 3 de dano de volta.
- **Armaduras**:
  - Cota de Malha;
  - Arnês de Placas: vantagem em Intimidação;
  - Brunea de Escamas: Ferimento no inimigo ao lado que acerta a armadura;
  - Armadura Samurai: Guarda se não andou;
  - Manto do Vento: +2 ou −2 na defesa;
  - Couraça do Contra-Ataque;
  - Peitoral de Dalpnor: −1 de resistência em profanos e o Fardo da Luz.
- **Escudos**:
  - Escudo de Investida: empurra depois de 2 passos em linha reta;
  - Placa de Luz: só protege de tiro e magia; tiro contra você −2;
  - Scutum da Legião: +2 de resistência em formação; sozinho não protege e anda 1.
- **Consumíveis**: todos os que têm ação.
  - Poções, runas, Bomba, Piche, Veneno Ácido (+1 e ignora resistência, como na carta nova), Óleo, Sangue de Batalha, Água Abençoada, Flecha Explosiva, Pergaminho do Desencantamento, Incenso...
  - Os de **"você ou um aliado adjacente"** têm um botão para cada aliado no menu Itens.
  - **Ração de Viagem** (carta nova): no descanso curto, compra 1 carta para a mão. Antes tirava fadiga.
  - **Pedra de Amolar**: gasta no descanso curto; +1 de dano até o fim da missão.
- **Acessórios e roupas**:
  - Corda de Arco da Penumbra, Paraquedas Élfico, Manopla de Bronze, Botas de Lince, Pergaminho Ancestral, Manto Camuflado;
  - Anel do Iniciado, Elmo de Touro, Bainha Impetuosa, Cinto Estelar, Selo de Sangue, Grevas do Vazio;
  - os 6 amuletos.
- **Magias dos livros**: 42 das 45.
  - Algumas estão simplificadas: a Bolha prende, mas ainda não afoga; a Tempestade de Brasas não se sustenta; a Névoa Brilhante não explode.
  - O Decreto dá 2 Medo e empurra; o Julgamento só marca; o Cântico da Ordem faz quem começa o turno dentro só andar ou só atacar.

### O que ainda não funciona
Na loja e na criação esses itens aparecem com "*".
- **Fora de combate, com o mestre**:
  - Pederneira, Espelho de Bolso, Bússola, Equipamento de Pesca, Máscara do Impostor, Poção de Feromônios;
  - a mensagem do Amuleto de Nebtor (o +1 em Diplomacia funciona);
  - Cavar e Estruturar, Luz Penetrante e Reflexo Líquido.
- **Ainda não**:
  - Montante do Frenesi, Arco Recurvo, Leque de Lâminas, Arco das Sombras, Arco da Maré, Balestra de Cerco;
  - a reação da Corrente de Caça e a da Lança da Muralha;
  - Couro Élfico, o Sacrifício do Peitoral de Dalpnor, Broquel Ágil;
  - Cachecol da Parceria, Botas Seccundas, Carta da Sorte, Ampulheta Trincada, Colar Vinculador, Espelho Arcano, Grilhão de Ferro;
  - Kit de Acampamento (o jogo não tem descanso longo ao relento);
  - Poções de Superação e de Reaprendizado.

## 2. Inventário por espaços

7. **Limites**:
   - Armadura 1, Costas 1, Cabeça 1, Pés 1;
   - Acessórios 2 (só 1 amuleto ou colar);
   - Armamentos e repertórios 4 (as duas armas, escudo, foco e livros);
   - Consumíveis especiais: 6 cargas;
   - Mochila 6. Tochas e rações vão 3 por espaço; kits e a vara de 3 metros ocupam 2.
   - A ficha não salva se passar do limite, e a loja recusa a compra.
8. **Criação**: o botão **"Consumíveis, mochila, roupas e livros"** abre o inventário, que mostra a ocupação no alto.
9. **O Kit Inicial de Aventura acabou**: os 8 itens ocupavam 11 espaços. Todo herói novo leva na mochila:
   - corda, lanterna, kit de reparos e pé de cabra (5 espaços), mais um pacote de tochas;
   - o **Ladino** troca o pé de cabra pelas **ferramentas de ladrão**.
   - O item da classe vai para o espaço dele: **Bandoleira** e **Corda de Arco** nos acessórios; ferramentas na mochila.
   - Heróis salvos antes recebem tudo isso sozinhos ao abrir.
10. **Só o que está vestido ou empunhado funciona**: um amuleto guardado não dá efeito.
11. **Troca de arma** (regra 11):
    - arma pequena ou média: **1 Movimento**, ou uma ação Padrão se o Movimento já foi;
    - com arma grande: continuam **2 ações Padrão**.
    - A Bandoleira continua com 2 trocas grátis por cena.

## 3. Economia

12. **Moedas**: 1 ouro (PO) = 100 pratas (PP) = 1.000 cobres (PC). Tudo aparece em moedas ("1 PO 20 PP").
13. **Preços**: os do estudo (espada longa 30 PP, poção de cura 12 PP, arnês 12 PO...).
    - Revenda pela loja de origem: vila e cidade 40%, especialista 35%, encomenda 30%, relíquia 25%.
14. **Lojas da vila**:
    - **Mercado da Doroteia**: consumíveis, ferramentas, roupas, acessórios, focos e livros.
    - **Forja do Bruno**: armas, armaduras e escudos.
    - Itens de vila, cidade e especialista estão à venda.
    - **Encomenda**: paga agora, o item chega ao fim da próxima missão vencida.
    - **Relíquias** não se compram; só se acham.
    - Comprar arma põe na segunda arma. Comprar armadura, escudo, foco ou roupa troca a atual, e a antiga é vendida pela revenda.
    - Tem também uma lista **"Vender"**.
15. **Contratos**, faixa da aldeia ou pequena guilda, para o grupo:
    - fazenda 100 PP;
    - cripta 150 PP;
    - pântano 200 PP;
    - catacumbas 300 PP.
16. **O resto do dinheiro**:
    - Estalagem ("descanso atendido"): 5 PP por herói.
    - Dinheiro inicial do grupo: 60 PP.
    - O dinheiro achado nos mapas agora é em pratas.
    - Campanhas salvas convertem sozinhas: o "ouro" antigo valia uma prata.

## 4. Classe Bruxo

17. **Os 10 pactos e as 18 cartas gerais** estão no jogo, com os textos da proposta v02. O arquivo é gerado por `tools/gerar_bruxo.py`.
18. **Criação**:
    - O Bruxo põe **1 patrono** na carta de herói. A outra metade é da raça ou do background.
    - O pacto traz de graça a **carta de pacto** e a **habilidade inicial A/B**.
    - O foco da classe é a Varinha Eletrizante (foco arcano), e o Bruxo começa segurando o foco.
    - Espírito é o atributo das magias.
    - O patrono do **Pacto Menor** se escolhe na criação, entre os outros nove.
19. **Fichas de Pacto**:
    - A carta de pacto guarda a reserva: **2 × nível** no começo de cada cena (nível do pacto = nível do grupo).
    - O Pacto Menor recebe 1 × nível.
    - Custos "X Pactos" viram **opções da carta**, por exemplo "Ave Fênix + 2 Pactos".
    - O crítico com o patrono à vista dá Pactos iguais ao nível.
20. **Cumprimentos que o jogo mede**:
    - Fênix: morte de monstro que você feriu ou que queimava.
    - Abismo: exílio voluntário.
    - Última Porta: assumir o golpe com Guarda.
    - Olho: o marcado estoura.
    - Caminhos: levar o inimigo até o aliado.
    - Grilhões: o inimigo gasta ação para se soltar.
    - Mesa Vazia: devorar 2 ou mais de Fadiga.
    - Trovão: carta chega ao limite.
    - Sonhos: o Atormentado pesa no inimigo.
    - Inverno: conservar a fadiga no fim do turno (nova opção na tela de fim de turno).
21. **Cobranças**:
    - **Medidas pelo jogo** (suspendem o pacto):
      - Abismo: a carta final do estouro vai ao exílio;
      - Última Porta: protegido longe;
      - Caminhos: ficou no mesmo lugar;
      - Trovão: ficou sem carga;
      - Inverno: gastou Pacto e andou;
      - Sonhos: a menor carta da mão inicial vai ao exílio.
    - **Com o mestre**: não mentir, aceitar rendições e matar monstros (Fênix, sem prazo definido).
    - Suspenso, o pacto não ganha nem gasta. A carta de pacto tem o botão **"Reparar o pacto"**.
    - Caminhos e Inverno reparam sozinhos quando o turno cumpre a reparação.
22. **Reações com Pacto são automáticas** quando valem a pena; o Registro conta o que aconteceu:
    - Malgor, Última Oferta e a Sentinela;
    - a Testemunha e o Carcereiro;
    - Niméria;
    - os benefícios menores de reação;
    - Retirar o Nome.
23. **Para o motor dos pactos funcionar, os inimigos agora têm Fadiga**:
    - cada Atormentado vira 1 ficha de Fadiga no começo do turno deles;
    - a Fadiga não faz nada sozinha;
    - é o que a Mesa Vazia devora.
24. **Ficha de Guarda**: até aqui ela não fazia nada. Agora, pelo glossário ("sofra ataque no lugar de aliado"), quando um inimigo vai ferir um herói, o aliado **ao lado** com Guarda pode gastar a ficha e receber o golpe. O jogo pergunta. Vale para todas as classes: Pele de Pedra, Samurai, Relicário, Ombro a Ombro...
25. **O que ainda falta no Bruxo**:
    - a ativada da Serpente Entre as Portas (aliado anda 1 ao ser alvo);
    - o passo junto ao protegido da Sentinela;
    - Manter o Canal e Patrono Presente: os inimigos não viram cartas de herói nem anulam magias;
    - Emprestar a Vontade e Ouvir a Reprimenda: com o mestre;
    - Segredo Entre as Cartas: as cartas iniciais já ficam à sua vista;
    - o scry 3 do Presságio é feito como 3 scry 1 seguidos.

## 5. Revisão das cartas de habilidade (PDF de 27/10)
26. **Faces revisadas** (os textos vêm do PDF; `tools/aplicar_revisao_cartas.py` até a planilha ser reexportada):
    - **Ombro de Aço**: só aliados **adjacentes** ganham +1 na defesa.
    - **Hino de Coragem**: bloqueia só **Medo e Confusão**.
    - **Ressurgir**: metade do descarte **arredondada para cima**.
    - **Preparar o Tiro**: depois de usar, **não anda** até o fim do turno.
    - **Conjuração Perfeita**: a magia custa **só 1** de fadiga (antes, 0).
    - **Mana Densa**: descarta 1 carta e faz **Raciocínio contra a Sabedoria** do conjurador para anular.
    - **Roubo Arcano** (antes não funcionava): Raciocínio contra Sabedoria; a magia vai para **outro alvo**. O jogo escolhe o inimigo mais perto do conjurador.
    - **Bote Fatal**: só ao **acertar**.
    - **Predador Absoluto** (antes não funcionava):
      - a presa é o inimigo visível mais perto;
      - o dobro das fichas que seus ataques põem nela;
      - Preparo no fim do turno se a feriu.
    - Textos ajustados sem mudança de regra: Ombro de Ferro, Avalanche, Flecha de Rede, Flecha Pesada, Adaga Fantasma, Torcer a Lâmina, Teologia e os lados que perderam o "Passiva:".

---

# Para você decidir
1. **Armas leves**: as cartas trazem a faca com dano 2; mantive o +1 da 0.13 (fica 3). Tiro o ajuste?
2. **Kit inicial**: o herói novo leva corda, lanterna, kit de reparos e pé de cabra, mais tochas. Prefere outra mochila inicial (kit de acampamento, pederneira)?
3. **Criação**: comuns, focos e livros básicos de graça. Prefere que a criação use dinheiro, e quanto?
4. **Contratos de 100 a 300 PP** e 60 PP iniciais: estão bons?
5. **Encomenda** chega ao fim da próxima missão vencida. Está bom?
6. **Bruxo**:
   - O nível do pacto acompanha o nível do grupo. Ou quer progressão própria?
   - A carta do patrono ficou com limite 4 de fadiga (a Fênix estava "a definir").
7. **Reações automáticas do Bruxo**: prefere que o jogo pergunte, como na Muralha?
8. **Fadiga dos inimigos** (vinda do Atormentado): quer que ela tenha efeito próprio (por exemplo, −1 no limite a cada 2)?
9. **Ficha de Guarda** funcionando como "sofrer o ataque no lugar do aliado ao lado": é isso?
