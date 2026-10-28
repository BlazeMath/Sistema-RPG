"""Consolida a Fênix e as propostas novas sem alterar as fontes da v01."""
from pathlib import Path
import copy
import json

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'classes/dados/bruxo'


def read(name):
    return json.loads((DATA / name).read_text(encoding='utf-8'))


def write(name, value):
    (DATA / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    original = read('pacto_fenix_v01.json')
    source = original['tres_cartas']
    a = source['habilidade_inicial']['lado_a']
    b = source['habilidade_inicial']['lado_b']
    old = read('novos_pactos_v01.json')
    fenix = {
        'id': 'BR-P00',
        'nome': 'Pacto da Fênix',
        'patrono': 'A Fênix',
        'tags': original['tags_pacto'],
        'estado': 'nucleo_confirmado_com_pendencias',
        'rotulo_estado': 'Núcleo confirmado pelo autor; cobrança e detalhes indicados abaixo ainda em aberto. O benefício menor é uma proposta.',
        'fonte_confirmada': 'classes/dados/bruxo/pacto_fenix_v01.json',
        'papel': 'Fogo em área e recuperação',
        'identidade': 'Consumir os inimigos em chamas e transformar esse fogo em recuperação, sustentando o poder com a morte de monstros.',
        'ciclo': 'Queimar → contribuir para a morte de monstros → ganhar Pacto → escolher entre explosão e recuperação.',
        'pacto': {
            'beneficio': 'Ganhe 1 ficha de Pacto ao presenciar a morte de um monstro pela qual você tenha sido responsável. Não é necessário dar o golpe final. Não foi definido alcance numérico para presenciar a morte.',
            'cobranca': 'Matar monstros. A obrigação precisa ter importância real para o Bruxo; prazo e quantidade ainda serão definidos.',
            'quebra': 'Consequência em aberto. O autor considerou perder acesso à habilidade ou sofrer dano, sem escolher uma opção.',
            'reparacao': 'Ainda não definida. A suspensão usada como proposta nos outros patronos não foi aplicada automaticamente à Fênix.',
            'habilidade_inicial': 'Ave Fênix / Absorver as Chamas',
        },
        'heroi': {
            'limite_fadiga': None,
            'passiva': source['heroi']['passiva'],
            'ativada': source['heroi']['ativada']['texto'] + ' A cura segue a regra normal de cura e exílio.',
            'desencadeada': source['heroi']['desencadeada']['texto'] + ' Inclui Fogo de outras fontes e Fogo hostil; o escopo espacial ainda não foi delimitado.',
            'critico': source['heroi']['critico'],
        },
        'habilidade': {
            'tipo': 'Magia Arcana',
            'requer': ['Pacto', 'Fogo', 'Fênix'],
            'lados': [
                {'lado': 'A', 'nome': a['nome'], 'custo_fadiga': a['custo_fadiga'], 'limite_fadiga': a['limite_fadiga'], 'acao': 'Padrão', 'texto': a['texto_revisado'].replace('\\n', '\n')},
                {'lado': 'B', 'nome': b['nome'], 'custo_fadiga': b['custo_fadiga'], 'limite_fadiga': b['limite_fadiga'], 'acao': 'Padrão', 'texto': b['texto_revisado'] + ' A cura é F + 2X: F é o número de fichas de Fogo removidas e X o de fichas de Pacto gastas. X pode ser zero. Siga a regra normal de cura e exílio.'},
            ],
        },
        'menor': old['fenix_menor']['beneficio'],
        'cobranca_menor': old['fenix_menor']['cobranca'],
        'pendencias': [
            'Prazo, quantidade de monstros, consequência e reparação da cobrança plena e menor.',
            'Escopo espacial do aumento do dano de Fogo. A inclusão de outras fontes permanece confirmada.',
            'Limite de Fadiga da carta de herói e a indicação explícita da ação de sua ativada ainda não foram definidos separadamente.',
        ],
        'teste': 'Avaliar o dano total da área: sem Pacto, os adjacentes recebem somente Fogo; com X Pactos, recebem 1 + 2X de dano direto, além do Fogo. Em Absorver as Chamas, a cura é F + 2X e mantém o exílio normal. Nenhuma cobrança nova foi fechada nesta inclusão.',
    }
    pacts = copy.deepcopy(old)
    pacts.update(titulo='Dez patronos do Bruxo, incluindo a Fênix', versao=2, estado='fenix_com_nucleo_confirmado_e_nove_patronos_propostos', referencia_regras='classes/dados/bruxo/regras_propostas_lote_v02.json')
    pacts['patronos'] = [fenix] + pacts['patronos'] + read('rascunho_patronos_potencia_v02.json') + read('rascunho_patronos_controle_v02.json')
    pacts['alteracoes_v02'] = ['Inclusão da Fênix com as três cartas e pendências preservadas.', 'Quatro patronos novos, totalizando dez opções de pacto pleno.']
    pacts.pop('fenix_menor', None)
    assert len(pacts['patronos']) == 10
    assert len({p['id'] for p in pacts['patronos']}) == 10

    skills = copy.deepcopy(read('habilidades_gerais_v01.json'))
    skills.update(titulo='Dezoito habilidades gerais propostas para o Bruxo', versao=2, regras='classes/dados/bruxo/regras_propostas_lote_v02.json')
    skills['cartas'] += read('rascunho_gerais_v02.json')['cartas']
    # Agrupa as nove cartas de 1 XP em três estratégias de três cartas.
    groups = {
        'Vínculos': ['BR-G01', 'BR-G05', 'BR-G08'],
        'Preço e poder': ['BR-G02', 'BR-G06', 'BR-G09'],
        'Potência especializada': ['BR-G03', 'BR-G04', 'BR-G07'],
    }
    for name, ids in groups.items():
        for card in skills['cartas']:
            if card['id'] in ids:
                card['grupo'] = name
    skills['cartas'].sort(key=lambda c: (0 if c['xp'] == 1 else 1 if c['xp'] == .5 else 2, c['id']))
    skills['estrategias_1xp'] = groups
    skills['observacao'] = '9 cartas A/B de 1 XP, 6 meias cartas de ½ XP e 3 cartas A/B de 2 XP: 18 entradas de catálogo e 30 faces. As meias cartas seguem a regra de combinar duas faces. As habilidades iniciais dos patronos e as cartas de herói/pacto são contadas à parte.'
    audit = read('contagem_habilidades_classes_v02.json')
    skills['comparacao_quantidade'] = {
        'resumo': 'O Bruxo tinha 15 entradas e 24 faces. Foram acrescentadas apenas três cartas A/B de 1 XP para igualar as cinco classes existentes: 18 entradas e 30 faces de habilidades gerais.',
        'classes': [dict(classe=classe, cartas_1xp=9, meias_05xp=6, cartas_2xp=3, entradas=18, faces=30) for classe in ['Guerreiro', 'Clérigo', 'Caçador', 'Mago', 'Ladino', 'Bruxo']],
        'criterio': 'Contagem do PDF Habilidades_Cartas.pdf por faces e códigos de carta: 9 pares de 1 XP + 6 meias cartas + 3 pares de 2 XP. Duas meias podem formar uma carta física; por esse critério, são 15 cartas montadas. Heróis, cartas de pacto e habilidades iniciais dos patronos ficam fora da comparação das habilidades gerais do Bruxo.',
        'adicoes': 'Novas cartas gerais: ' + '; '.join(c['nome'] for c in skills['cartas'] if c['id'] in ['BR-G07', 'BR-G08', 'BR-G09']) + '.',
        'auditoria': 'classes/dados/bruxo/contagem_habilidades_classes_v02.json',
    }
    assert len(skills['cartas']) == 18
    assert sum(len(c['lados']) for c in skills['cartas']) == 30
    assert {xp: sum(c['xp'] == xp for c in skills['cartas']) for xp in [1, .5, 2]} == {1: 9, .5: 6, 2: 3}
    assert audit

    rules = copy.deepcopy(read('regras_propostas_lote_v01.json'))
    rules.update(titulo='Bruxo — regras de trabalho para dez patronos', versao=2)
    rules['convencoes_propostas'] = [s.replace('dos cinco patronos novos', 'dos nove patronos novos').replace('Nos patronos deste lote,', 'Nos nove patronos propostos,') for s in rules['convencoes_propostas']]
    rules['convencoes_propostas'] += [
        'A Fênix está no catálogo com as definições já confirmadas; limite de Fadiga do herói, ação explícita da ativada, escopo do Fogo e detalhes da cobrança permanecem identificados como pendências. As convenções propostas não resolvem essas pendências automaticamente.',
        'O conjunto geral agora acompanha a quantidade das cinco classes: nove cartas A/B de 1 XP em três estratégias, seis meias cartas de ½ XP e três cartas A/B de 2 XP. As dez habilidades iniciais A/B dos patronos ficam em um catálogo separado desse total.',
    ]
    rules['testes_prioritarios'] += [
        'Fome: cura segue o exílio normal e não deve devolver mais vida do que o confronto e seus custos permitem sustentar.',
        'Tempestade: contar ações investidas em preparar e descarregar; verificar se o pico de dano compensa a preparação sem repetir ganhos sobre o próprio gasto.',
        'Pesadelo: testar a remoção de Atormentado, a pressão de Fadiga e a duração de Confusão; o alvo deve ter caminhos reais para reagir.',
        'Inverno: verificar a troca entre conservar Fadiga, abrir mão da recuperação e permanecer na posição; a transferência não elimina Fadiga nem cria uma segunda reserva.',
        'Três novas cartas gerais: combinar com os dez patronos e com Manifestação Dupla, conferindo gatilhos, custos e número de ativações.',
    ]
    write('novos_pactos_v02.json', pacts)
    write('habilidades_gerais_v02.json', skills)
    write('regras_propostas_lote_v02.json', rules)
    registry_path = ROOT / 'organizacao/especialidades/classes.json'
    registry = json.loads(registry_path.read_text(encoding='utf-8'))
    development = registry['classe_em_desenvolvimento']
    previous = development.get('lote_proposto', {})
    if previous.get('versao') == 1:
        development.setdefault('historico_lotes', {})['v01'] = previous
    development['lote_proposto'] = {
        'versao': 2,
        'estado': 'fenix_com_nucleo_confirmado_demais_propostas_nao_aprovadas',
        'patronos': [p['nome'] for p in pacts['patronos']],
        'total_patronos': 10,
        'fenix_incluida': True,
        'novos_nesta_rodada': [p['nome'] for p in pacts['patronos'] if p['id'] in ['BR-P06', 'BR-P07', 'BR-P08', 'BR-P09']],
        'cartas_gerais': 18,
        'faces_gerais': 30,
        'distribuicao_xp': {'1_xp': 9, 'meia_carta': 6, '2_xp': 3},
        'dados_patronos': 'classes/dados/bruxo/novos_pactos_v02.json',
        'dados_gerais': 'classes/dados/bruxo/habilidades_gerais_v02.json',
        'contagem_comparada': 'classes/dados/bruxo/contagem_habilidades_classes_v02.json',
        'relatorio': 'outputs/01a17d39-9806-7153-9510-d82d1e7aaeea/classes/Bruxo_Pactos_e_Habilidades_Proposta_v02.html',
        'cobranca_fenix': 'Continua em aberto; não foi alterada.',
    }
    registry_path.write_text(json.dumps(registry, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'patronos': len(pacts['patronos']), 'habilidades_gerais': len(skills['cartas']), 'faces_gerais': 30}, ensure_ascii=False))


if __name__ == '__main__':
    main()
