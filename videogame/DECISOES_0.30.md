# Sistema 21 — versão 0.30

## Investigador

A criação de heróis oferece o Investigador. A ficha pronta da Elisa usa Detetive
Analítico, Coleta Metódica / Ligar os Pontos e Hipótese de Trabalho / Contraprova.
O catálogo preserva os quatro heróis, as 18 opções de habilidade e os custos da
edição de teste v02. O gerador em `tools/gerar_investigador.py` usa a cópia dessa
edição guardada no projeto.

Evidências pertencem ao grupo e aparecem no Registro. Pistas são fichas pessoais
nas cartas. O menu **Ações → Usar Pistas** permite gastar X fichas e uma Ação
Padrão para comprar X cartas do próprio baralho. Gastar ou perder fichas mantém
as evidências registradas. Ganhos e deduções têm limites e chaves por descoberta
para que a mesma observação não gere fichas de novo.

## Vau-Cinzento

O menu principal abre Vau-Cinzento com o grupo selecionado. As opções específicas
da classe aparecem nos pontos do mapa e exigem a face ativa e seus custos. No
poço e no boticário, Hipótese de Trabalho prepara scry 3 para a verificação
indicada. Coleta Metódica é oferecida antes das cartas iniciais e só rende ficha
quando o teste revela informação nova. O Detetive também pode Examinar os
Vestígios no poço. Ligar os Pontos e Conclusão Fundamentada cruzam as evidências
que o grupo já tem e registram inferências sem aumentar o total de evidências.

Explorar a Descoberta e Orientar a Verificação atuam antes da compra. Corrigir a
Hipótese e Segundo Caminho atuam antes das consequências de uma falha. Contraprova
vem depois da falha definitiva e oferece outra verificação sem mudar o resultado.
A acusação continua exigindo três evidências distintas. Arrombar continua sendo
uma rota independente, disponível para qualquer grupo.

## Recorte da edição digital

- A v0.30 segue o catálogo de teste v02. As deduções de Vau-Cinzento são escritas
  na missão, e as sugestões de economia de Pistas do motor de investigação de
  03/11 continuam como proposta.
- Expor o Perfil e Desmontar a Versão usam teste automatizado contra Espírito.
  A comunicação com inimigos exige alcance curto e visão mútua e usa as categorias
  humanoide e goblinoide. Inimigos sem cartas viráveis recebem as Penalidades de
  Desmontar a Versão. Conclusão Fundamentada dá Preparo ao Investigador nesta fase.
- Sequência Calculada, Encontrar uma Abertura, Pergunta Precisa, Reconhecimento,
  Abrir Caminho, Sair do Pior, Investigar sob Pressão, Recolher Evidência,
  Reconstrução Completa, Antecipar o Plano e Plano de Extração ainda precisam de
  adaptação. Seus textos estão no catálogo para consulta. Identificar o Padrão
  depende de uma dedução com esse gatilho previsto pela fase.
- Para partidas em rede, todos os jogadores precisam usar a v0.30.
