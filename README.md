# Sistema 21 — Sistema de RPG

Acervo do Sistema 21 / Coleção Masmorras (MMR): regras de mesa, cartas, artes,
documentos de trabalho e protótipo do videogame em Godot 4.4/GDScript.

## Organização

| Caminho | Conteúdo |
| --- | --- |
| `SISTEMA_21_Estado_do_Projeto.md` | Resumo geral; consultar também as decisões posteriores. |
| PDFs na raiz | Habilidades, heróis, origens e manual de mesa. |
| `organizacao/` | Contexto compartilhado, especialidades, fontes e recortes de histórico. |
| `classes/` | Revisões, dados e fontes das classes. |
| `regras/` | Decisões de regras registradas. |
| `producao_cartas/` | Dados, artes, PDFs e pacotes de produção, incluindo versões anteriores. |
| `output/`, `outputs/`, `tmp/` | Entregas, estudos, provas e arquivos de trabalho preservados. |
| `videogame/` | Código extraído do protótipo v0.23, sem mudanças de regras. |
| `Sistema21_projeto_v0.23.zip` | Pacote original do protótipo, preservado. |

## Baixar o acervo completo

Este repositório usa **Git LFS** para PDFs, imagens, ZIPs e outros arquivos binários.
Para obter os arquivos completos, instale Git e Git LFS e execute:

```sh
git lfs install
git clone https://github.com/BlazeMath/Sistema-RPG.git
cd Sistema-RPG
git lfs pull
```

O download de ZIP oferecido pelo GitHub pode conter apenas ponteiros dos arquivos
LFS, dependendo da configuração do repositório. O clone com Git LFS é o caminho
recomendado para recuperar todo o material.

## Abrir o videogame

Importe `videogame/project.godot` no Godot 4.4 (GDScript). O projeto usa o
renderizador GL Compatibility. As convenções estão em `videogame/CLAUDE.md` e as
decisões mais recentes em `videogame/DECISOES_0.23.md`; o README interno ainda
descreve a versão 0.21.

Para executar os testes existentes, dentro da pasta `videogame/`:

```sh
godot --headless --path . -s res://tests/run_tests.gd
```

## Estado das regras e materiais

O acervo inclui propostas, estudos, fontes históricas e arquivos em andamento.
A presença de um documento ou de uma regra no código não significa aprovação
para o jogo de mesa. Consulte `organizacao/contexto_compartilhado.json`, os
registros de cada especialidade e as decisões explícitas mais recentes do autor.

O envio ao repositório preserva os materiais existentes. Caches de ferramentas,
arquivos temporários do sistema operacional e credenciais ficam fora do Git.
