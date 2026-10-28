# Versão 0.7 — decisões tomadas sem o Lucas (para revisar)

## Queda (regra do Lucas)

- Dano de queda = 3 × (n − 1), sendo n os quadrados caídos. Cair 1 quadrado não causa dano.
- Queda de mais de 2 quadrados: o herói pode testar Acrobacia (Destreza + Acrobacia), com dificuldade 15 + n, para sofrer metade do dano.

Interpretações minhas:

1. **Passar no teste**: segui o livro ("total maior que a dificuldade"). Com 3 quadrados, a dificuldade é 18 e é preciso tirar 19 ou mais. Se você quis dizer "18 ou mais", é só trocar um número.
2. **Metade arredonda para cima**, como a ficha de Bloqueio: 6 → 3, 9 → 5.
3. **O teste é opcional**: aparece um botão "Tentar amortecer" ou "Cair sem testar". Ele não custa ação, mas gasta cartas como qualquer teste.
4. **Parkour não é perícia**: no livro, Parkour é uma ação feita com Acrobacia. Por isso o teste é sempre de Acrobacia.
5. **O teste de amortecer é de movimento**: sofre a penalidade de armadura (limite 19 na média, 17 na pesada).
6. **Quedas na trilha**:

    | Onde | Quadrados | Resultado |
    | --- | --- | --- |
    | Paredão, perto do topo | 3 | 6 de dano, ou 3 amortecendo |
    | Fenda | 2 | 3 de dano |
    | Pedras do riacho e ponte (cair na água) | 1 | sem dano |

    Ser arrastado pela correnteza (3) e escorregar no vau (2) continuam como dano comum, não como queda.

## Perícias (regra do Lucas)

- Quatro perícias com 3, seis com 2 e oito com 1. As outras 21 ficam com 0.
- A lista é a do livro, capítulo 5: 13 físicas, 13 mentais e 13 sociais.

Interpretações minhas:

7. **A tela de perícias** abre pelo botão "Escolher perícias" na ficha. Quando uma cota enche, os botões daquele valor ficam travados até você liberar uma perícia.
8. **Nos testes**, o modificador é atributo + perícia, e nenhum dos dois conta para estourar. Na trilha:

    | Ação | Perícia |
    | --- | --- |
    | Nadar | Natação |
    | Atravessar a pé | Fortitude |
    | Saltar | Atletismo |
    | Correr pelas pedras, equilibrar-se | Acrobacia |
    | Forçar o baú | Atletismo |
    | Destrancar | Ladinagem |
    | Rastros | Sobrevivência (antes estava "Rastrear", que não existe no livro) |
    | Grãos, cinzas, procurar no paredão, toca | Investigação |
    | Escalar | Escalada |

9. **Iniciativa** agora vem da perícia Iniciativa: 2 cartas + Destreza + Iniciativa, como o CLAUDE.md já previa.
10. **Heróis salvos antes da 0.7** ficam sem perícias e só jogam depois que você as escolher e salvar de novo. Sem herói válido, o jogo usa o herói padrão.
11. **Perícias do herói padrão** (Guerreiro de Teste):
    - Com 3: Atletismo, Luta, Fortitude e Intimidação.
    - Com 2: Escalada, Natação, Reflexos, Guerra, Sobrevivência e Liderança.
    - Com 1: Acrobacia, Pontaria, Iniciativa, Cavalgar, Medicina, Monstros, Natureza e Intuição.
12. **As faixas da trilha não mudaram**. Como a perícia agora soma, os testes ficaram mais fáceis que na 0.6. Isso combina com o livro, cujas tabelas já contam com atributo + perícia.
13. **Luta, Pontaria e Reflexos ainda não fazem nada** no combate: ataque e defesa continuam só com as cartas, como você pediu.
