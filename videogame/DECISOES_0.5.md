# Versão 0.5 — decisões tomadas sem o Lucas (para revisar)

Tudo aqui é provisório e fácil de mudar. Os números de combate ficam em `core/dados_batalha.gd`.

## Regras aplicadas (confirmadas pelo Lucas)

- Testes de ataque e defesa: só cartas, mais ajustes de habilidade. Inimigos também.
- Dano = diferença + dano da arma + atributo da arma (Destreza para armas leves e de tiro, Força para as outras) − resistência.
- Atributos na criação: dois 3, dois 2, três 1 e dois 0. XP escolhido entre 0 e 10.
- Metades de herói: da classe, da raça e do background.
- Fadiga: no fim do turno sai 1 de uma carta escolhida pelo jogador.
- Imobilizado: a ficha fica numa carta; o herói perde a ação de Movimento e não rebaixa Padrão. Sai ao virar a carta.

## Interpretações minhas

### Cartas
1. **Carta de herói tem dois lados**: cada metade é um lado. Só o lado de cima funciona; virar troca de metade.
2. **Meias cartas**: duas formam uma carta de 1 XP, com um lado de cada.
3. **Ativar exige espaço de fadiga**: não dá para ativar se o custo passa do limite da carta.
4. **"Habilidades de arma"** (Foco Mortal): as que fazem um ataque. Custam 1 de fadiga a menos.
5. **Ficha de Preparo**: usada automaticamente ao virar uma carta, no lugar da ação.
6. **Ombro de Ferro**: só anda o quadrado se precisar para chegar ao lado do alvo.
7. **Postura da Cascavel**: o revide causa dano da arma + atributo − resistência. O jogo oferece um botão após uma defesa bem-sucedida.
8. **Segundo Vento**: sempre cura (a opção de tirar fadiga fica para depois).
9. **Bloqueio**: corta o próximo dano à metade (arredonda para cima).
10. **Crítico de Tomar a Posição**: põe Preparo e Foco na carta de herói (não vira outra carta).
11. **Ombro de Ferro e Força 3**: se o herói errar mas a Força 3 causar dano, o alvo fica imobilizado do mesmo jeito, porque a carta diz "se causar dano".
12. **Imobilizado não impede movimento vindo de habilidade** (Reposicionar, Ombro de Ferro, Tomar a Posição).
13. **Inimigos imobilizados**: a ficha fica neles. Gastam a ação Padrão para tirá-la quando não têm o que atacar.
14. **Lados de perícia** (a maioria das cartas de Humano e Soldado): podem ser escolhidos, mas não têm efeito na batalha ainda.

### Atributos
14. **Força 3**: dano igual à Força mesmo errando. **Força 5**: Força + arma. Só quando o ataque usa Força. A resistência reduz esse dano.
15. **Destreza 3**: botão opcional "+1" no ataque, que conta para estourar.
16. **Percepção 3**: quando o herói ataca, a carta fechada do defensor fica à vista.
17. **Ainda sem efeito**: Destreza 5, Constituição 3 e 5, Sabedoria 3 e 5, Raciocínio 3 e 5, Percepção 5, Espírito, Mentira e Diplomacia.

### Itens
18. **Ordem do dano**: primeiro o escudo, depois a armadura, depois o baralho (automático).
19. **Sem armadura**: ao se defender bem, a carta aberta da defesa volta ao fundo do baralho. **Armadura leve**: uma carta aleatória da defesa volta.
20. **Armaduras média e pesada**: exilam 1 carta do descarte no fim de cada turno do herói, enquanto inteiras.
21. **Armadura pesada**: limite 22 na defesa, enquanto inteira.
22. **Cota de Malha**: na primeira vez que quebraria na cena, segura o golpe inteiro e fica com 1 de vida.
23. **Arma pesada ao errar**: tritura 1 carta e Velocidade −1 até o fim do próximo turno.
24. **Arma pequena**: +1 opcional no ataque. Quando o herói atacou na rodada, ele defende com as cartas à vista.
25. **Escudo**: não combina com arcos nem com armas grandes. A planilha não tem escudos comuns, então usei os escudos-base do livro (leve 5/1, pesado 10/2).
26. **Armas de alcance**: só os dois arcos (Arco Curto e Arco de Guerra). Arremessáveis e besta pesada ficam para quando houver munição e recarga.
27. **Consumíveis que funcionam**: Poção de Cura Pequena, Poção de Mana Pequena e Veneno Ácido. Os outros aparecem marcados com *.

### Conflito para você resolver
28. **Distâncias**: a planilha de armas diz Curta 1–3, Média 4–6, Longa 7–10. Mantive a sua decisão (curto até 4, médio 5–8, longo 9–12).
29. **Tiro com inimigo ao lado**: a planilha manda desvantagem para quem atira com um inimigo adjacente. Apliquei.

### IA (nível 2)
30. **Chance de estouro**: o inimigo calcula a chance real pelas cartas que restam no baralho dos inimigos, e cada perfil aceita um risco: Bruto 55%, Covarde 25%, Atirador 40%.
31. **Defesa revelada**: atacando contra uma defesa à vista, o inimigo tenta passar o valor revelado.
32. **Defendendo**: estima a carta fechada do atacante em 7. Se o atacante estourou, para assim que empatar.

### Cenários
33. **Goblins**: Desordeiro (Covarde, vida 12, dano 4 + Força 2), Brigão (Bruto, Força 3, resistência 1) e Atirador (vida 8, arco 3 + Destreza 2).
34. **Chefe Goblin**: Bruto, vida 40, dano 5 + Força 3, resistência 1, 2 ataques por turno.
35. **Simulação**, com um herói que só ataca e defende no automático:

    | Cenário | Vitórias | Observação |
    | --- | --- | --- |
    | X1 contra o Chefe Goblin | 73% | equilibrado |
    | Arena contra 3 goblins | 91% | fácil; a armadura com escudo segura muito dano |

## Ainda não programado (Guerreiro)

- Provocar ↔ Castigo
- Parede de Escudos ↔ Escudo Ágil
- Avanço Combinado ↔ Aguentem, Recrutas!
- Golpe de Oportunidade (precisa do ataque de oportunidade)
- Instruir Armamento ↔ Movimento Guiado
- Metade de herói Mil Ofícios
