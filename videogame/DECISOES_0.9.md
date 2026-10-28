# Versão 0.9 — decisões tomadas sem o Lucas (para revisar)

## Fichas que não somem (suas regras)

- Sangramento, Veneno e Fogo causam 1 de dano por ficha e só saem com o que as tira explicitamente.
- Veneno e Fogo causam o dano no início do turno de quem tem a ficha; Sangramento, no fim.
- Cartas genéricas que dizem "remova uma ficha" (Água Benta, Primeiros Socorros…) **não** tiram essas três, porque você pediu habilidades que digam isso explicitamente.

Interpretações minhas:

1. **Tratar sangramento**: novo botão na barra de ações.
   - Custa uma ação Padrão e serve para você mesmo ou para um aliado adjacente.
   - O teste é Medicina + Sabedoria, nível médio (22).
   - Se passar, tira **todas** as fichas de Sangramento. Se falhar, nada acontece.
2. **Kit Médico** (inventei): consumível que tira todo o Sangramento, sem teste. Custa uma ação Padrão.
3. **Fogo**:
   - Virar a carta que tem a ficha tira o Fogo dela.
   - Entrar na água (rio, vau, nadar) tira todo o Fogo do personagem.
   - **Espalha** no início do turno de quem está pegando fogo:
     - pega em 1 outra carta do personagem que ainda não tem Fogo;
     - pega em cada pessoa adjacente que ainda não tem Fogo;
     - pega nos objetos inflamáveis adjacentes (feno, tenda, saco, cerca).
   - Um objeto em chamas queima por 3 rodadas e depois vira cinzas: sai do mapa e abre passagem. Quem termina ao lado das chamas pega fogo.
   - Fogo numa pessoa não acaba sozinho.
   - Constituição de Pedra (Anão) reduz em 2 o dano de fogo.

## Ataque mágico e focos

4. **Dano do ataque mágico** = diferença do teste + atributo de conjuração (Mago: Raciocínio; Clérigo: Sabedoria) + dano do foco + dano extra da magia.
5. **Focos** (inventei os valores):

   | Foco | Dano | Mãos | Outro efeito |
   | --- | --- | --- | --- |
   | Varinha | +2 | 1 | — |
   | Orbe | +1 | 1 | +1 no limite de defesa |
   | Cajado | +3 | 2 | não combina com arma de duas mãos |
   | Símbolo Sagrado | +2 | 1 | — |

   - O foco ocupa a mão do escudo: um herói com foco não usa escudo.
   - **Sem foco não há ataque mágico.** As magias de cura e proteção continuam funcionando sem foco.
   - Na criação há uma lista "Foco mágico". Um Mago ou Clérigo sem foco recebe um aviso, mas pode salvar a ficha.

## Dificuldade dos testes

6. **Escala** implementada como você descreveu. Cada nível usa o menor valor da faixa (atingir basta):

   | Nível | Só cartas | Atributo ou perícia | Atributo + perícia |
   | --- | --- | --- | --- |
   | Muito fácil | 12 | 15 | 18 |
   | Fácil | 14 | 17 | 20 |
   | Médio | 16 | 19 | 22 |
   | Difícil | 18 | 21 | 24 |
   | Muito difícil | 20 | 23 | 26 |

   - Reescrevi todos os testes da trilha e da fazenda com um nível; o número sai do tipo do teste. Exemplos:
     - Ler os rastros com Sobrevivência: fácil (17).
     - Só Percepção: difícil (21).
     - Investigação + Raciocínio: médio (22).
   - Na tela, cada botão mostra o nível e o número.
7. **Mantive as tabelas do livro** para nadar, escalar, saltar e amortecer queda (15 + n). Elas já trazem números próprios. Quer convertê-las para a escala também?
8. **Testes resistidos** (Provocar, por exemplo): a dificuldade = 2 cartas do baralho dos inimigos + o atributo do alvo. Atingir o valor vence.

## Raças e backgrounds

9. Entraram **todas** as cartas e metades de herói das raças (Humano, Elfo, Anão, Halfling, Orc) e dos backgrounds (Soldado, Bandido, Escravo, Explorador, Fervoroso).
   - O que depende de coisas que ainda não existem fica marcado na criação como "parcial" ou "sem efeito", com o motivo. Exemplos: penumbra, descanso longo, línguas, agarrar, roubo, ação de ajudar, clima, tipos de dano, Caído.
10. **Escolhas na criação**: Mente Maleável, Aprendiz Silencioso, Maestria de uma Vida e Mil Ofícios pedem perícias ou atributos.
    - As listas aparecem na coluna do equipamento quando a carta é marcada.
    - A ficha só fica pronta quando todas as escolhas estão feitas.
    - Mente Maleável ainda não confere se a perícia é menor que 3.
11. **Refazer testes**: ao falhar um teste, se o herói tem uma carta que permite refazer, o resultado ainda não vale. Aparecem botões "Refazer o teste" e "Aceitar o resultado".
    - Persistência Humana: teste com perícia.
    - Olhar Esperto: testes de procurar.
    - Mas Veja Bem: Diplomacia ou Mentira; vira a carta.
    - Impostor: Mentira; descarta a menor carta da mão, uma vez por cena.
12. **Halfling é pequeno.** Os goblins comuns também são pequenos; o chefe não. A Toupeira é grande.
    - O tamanho é usado por Matador de Gigante e pelas cartas que comparam tamanhos.
13. **Sorte dos Pequenos**: um estouro vale 21, uma vez por cena.
14. **Braço de Labuta**: +1 de Força enquanto o lado está para cima.

### Problema na planilha

15. **Mestre das Cavernas** (Explorador) custa 3 de fadiga, mas o limite da carta é 2. Do mesmo jeito que a Flecha de Rede, nunca dá para usar.

## Ataques de oportunidade e reações (início da próxima parte)

16. **Quem tem ataque de oportunidade**:
    - Goblin Brigão (arena, trilha e fazenda);
    - Chefe Goblin;
    - Rokk;
    - Toupeira Atroz.

    Goblins pequenos e arqueiros não têm.
17. **Quando acontece**: sair de um quadrado adjacente a esse inimigo provoca o ataque.
    - O inimigo precisa estar alerta e ter a Reação do turno.
    - O movimento para, o ataque acontece (você defende normalmente) e depois o herói termina o caminho, se ainda estiver de pé.
18. **Não provocam**:
    - movimentos de habilidades: Pé Ligeiro, Salto de Recuo, Passo de Sombra, Tomar a Posição;
    - movimentos de efeitos: empurrões, travessias de interação.
19. **Heróis**: Golpe de Oportunidade (Guerreiro) faz o mesmo contra inimigos que saem de perto.
20. **Castigo**: botão de Reação depois que um inimigo ataca um aliado adjacente ao herói com a carta. O herói ataca de volta.
21. **Provocar**:
    - O teste usa o maior entre Espírito e a perícia Irritar, contra Sabedoria do alvo (resistido).
    - Passou: o alvo ataca o provocador no próximo turno dele.
22. **Ainda não**: Lâmina Rápida e Tiro Rápido (reações de ataque), gastar Sombra para escapar do ataque, momentum, áreas e zonas.

## Para conversar na volta

- Medicina médio (22) para estancar: está bom, ou depende de quantas fichas?
- Valores dos focos e a regra foco × escudo.
- Converter as tabelas de movimento do livro para a escala nova?
- Quais outros inimigos devem ter ataque de oportunidade.
