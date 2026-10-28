# Sistema 21 — o videogame

RPG tático de grupo, em turnos e visão isométrica, baseado no Sistema 21: o vinte-e-um substitui os dados e o baralho do personagem é a sua vida.

**Estado atual: versão de teste 0.21 — interface nova: menus que abrem com o mouse, iniciativa em quadro, mão em leque, fichas do herói e do monstro, carta de arma, efeitos visuais e sons; antes: tela de fim de turno, uma ficha de cada tipo por carta (escolhida pelo jogador), Foco entre a carta aberta e a fechada, correções do playtest; antes: campanha em ciclos de 3 missões com níveis, pontos de descanso que salvam no meio da missão, névoa em degradê, luz dinâmica e cenário interativo; antes: personagens e cenários em 3D (modelos KayKit, CC0), menu de pausa no Esc e jogos salvos na vila; antes: o Pântano dos Afogados e inimigos que conjuram; antes: segunda arma e mãos, cartas desenhadas como cartas, heróis prontos e música; antes: escuro e luz, devoções, a cripta e a vila; antes: cartas combinadas no ataque e repertório; balanceamento com o dano 7; névoa de guerra; áreas e zonas, focos do PDF e inimigos por patamar; antes: grupo de até 4 heróis, todas as classes, raças e backgrounds, a missão da fazenda Vale Seco, fichas de Sangramento/Veneno/Fogo que não somem sozinhas, focos mágicos e ataques de oportunidade.** Valores provisórios. As decisões que o Claude tomou sozinho estão nos arquivos `DECISOES_0.x.md` (o mais novo é o `DECISOES_0.21.md`).

## Como jogar

1. Extraia o `Sistema21_Windows_v0.21.zip` e abra o `Sistema21.exe`.
2. Na primeira vez, o Windows pode mostrar "O Windows protegeu o computador" (o jogo ainda não tem assinatura digital). Clique em **Mais informações → Executar assim mesmo**.
3. No menu, abra **Criar e escolher heróis**: monte os heróis (as perícias ficam no botão **Escolher perícias**) e salve cada um. Marque até 4 na lista **Grupo**.
4. Volte ao menu e escolha **Missão**, **Exploração**, **X1** ou **Arena**. Cada herói do grupo joga no seu turno.

| Comando | Ação |
| --- | --- |
| Clique num quadrado azul | Andar (gasta a ação de Movimento; depois rebaixa uma Padrão) |
| Clique num goblin marcado em vermelho | Atacar com a arma (ação Padrão) |
| Clique num marcador **!** | Interagir: escolha uma opção (ou cancele), faça o teste e veja o que aconteceu |
| Janela de dano | Use − e + para dividir o dano entre escudo, armadura e baralho; Enter confirma |
| I | Inventário (usar poções e outros consumíveis) |
| WASD ou setas · roda do mouse | Mover a câmera · aproximar e afastar |
| Quadros do grupo (acima da barra) | Clique para ver as cartas e o inventário de um herói |
| Painel "Cartas de habilidade" | **Usar** uma habilidade (se pedir alvo, clique no goblin) · **Virar** a carta (1 ação Padrão) |
| Clique no seu baralho ou Espaço | Puxar uma carta na mesa de 21 |
| Clique numa carta da mão | Jogar a carta no teste (conta para estourar) |
| Botões na mesa | Ajustes opcionais (Destreza +1, arma pequena +1, Firmar os Pés +2), Foco Marcial, revide da Postura da Cascavel |
| Enter | Parar / continuar / confirmar |
| E | Encerrar o turno (o jogo pergunta de qual carta sai a fadiga) |
| N · Esc | Recomeçar · fechar janela, cancelar alvo / voltar ao menu |

Os heróis criados ficam salvos no computador (pasta de dados do Godot, arquivo `herois.json`).

## Como colocar no GitHub (sem terminal)

1. Extraia o arquivo `.zip` numa pasta do seu computador.
2. Abra o repositório no navegador: https://github.com/lucassebajos/Sistema-21
3. Clique em **Add file → Upload files**.
4. Abra a pasta extraída, selecione **todo o conteúdo dela** (todas as pastas e os arquivos soltos) e arraste para a página.
5. Clique em **Commit changes**.

Nas próximas entregas é igual: arraste o conteúdo novo por cima, e o GitHub substitui os arquivos que mudaram.

## Como abrir no Godot

1. Baixe o Godot 4.4 em https://godotengine.org/download (versão padrão, **não** a ".NET").
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.

## Estrutura

| Pasta | O que tem |
| --- | --- |
| `core/` | Motor de regras: cartas, baralho e zonas, teste de 21, combate, iniciativa, grid, batalha, IA, duelo |
| `ui/` | Telas: menu, criação de heróis, mapa em grid (exploração, X1 e arena), mesa de 21 pura |
| `assets/` | Fontes (DejaVu, licença livre) |
| `data/cartas/` | Cartas exportadas da planilha oficial (JSON) e o relatório da exportação |
| `tools/` | Exportador da planilha (`exportar_cartas.py`) |
| `tests/` | Testes automáticos das regras |

## Para quem programa

- Testes: `godot --headless --path . -s res://tests/run_tests.gd`
- Executável de Windows: `godot --headless --path . --export-release "Windows Desktop" export/Sistema21.exe`
- Capturas de tela automáticas: `xvfb-run godot --path . --rendering-driver opengl3 -s res://tools/capturar_batalha.gd` (ou `capturar_exploracao.gd` para a trilha, `capturar_telas.gd` para o duelo)
- Exportar cartas: `python tools/exportar_cartas.py SISTEMA_21_Cartas_Oficial.xlsx` (precisa de `openpyxl`)
- Convenções e decisões de regra: veja `CLAUDE.md`.
