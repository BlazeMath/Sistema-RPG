"""Verifica integridade do catálogo; não é simulação de equilíbrio."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'classes/dados/bruxo'


def read(name):
    return json.loads((DATA / name).read_text(encoding='utf-8'))


def main():
    pacts = read('novos_pactos_v02.json')['patronos']
    skills = read('habilidades_gerais_v02.json')['cartas']
    assert len(pacts) == 10 and len({p['id'] for p in pacts}) == 10
    assert len(skills) == 18 and len({c['id'] for c in skills}) == 18
    assert sum(len(c['lados']) for c in skills) == 30
    assert {xp: sum(c['xp'] == xp for c in skills) for xp in [1, .5, 2]} == {1: 9, .5: 6, 2: 3}
    for p in pacts:
        assert len(p['habilidade']['lados']) == 2
        assert [f['lado'] for f in p['habilidade']['lados']] == ['A', 'B']
        assert all(f['texto'] and f['custo_fadiga'] >= 1 for f in p['habilidade']['lados'])
        assert all(p['heroi'][k] for k in ['passiva', 'ativada', 'desencadeada', 'critico'])
        assert all(p['pacto'][k] for k in ['beneficio', 'cobranca', 'quebra', 'reparacao', 'habilidade_inicial'])
        assert p['menor'] and p['cobranca_menor']
    by_id = {p['id']: p for p in pacts}
    for original in read('novos_pactos_v01.json')['patronos']:
        assert by_id[original['id']] == original, original['id']
    general_by_id = {c['id']: c for c in skills}
    for original in read('habilidades_gerais_v01.json')['cartas']:
        assert general_by_id[original['id']] == original, original['id']
    fenix = by_id['BR-P00']
    source = read('pacto_fenix_v01.json')['tres_cartas']
    assert fenix['habilidade']['lados'][0]['texto'] == source['habilidade_inicial']['lado_a']['texto_revisado'].replace('\\n', '\n')
    assert fenix['habilidade']['lados'][1]['texto'].startswith(source['habilidade_inicial']['lado_b']['texto_revisado'])
    assert fenix['heroi']['limite_fadiga'] is None and fenix['pendencias']

    preserved = {
        'Habilidades_Cartas.pdf': '828802069bb45066e045b8f0803aa54395d16d6e05749c83bfcb35a42ded6fcf',
        'classes/dados/bruxo/pacto_fenix_v01.json': '69668a362895778d7827fb63e92a9818cd2debc1cdb13f754b2a6d9c39d183cc',
        'classes/dados/bruxo/novos_pactos_v01.json': '8aa773fbb88a9e617b509af387187f16a93c1c444fbbf1b56eb5e4fcca99d7ae',
        'classes/dados/bruxo/habilidades_gerais_v01.json': '28942ef04aa76e2ca91f0bd71447315e94d2b0dbe8f24e874c060f9ef9a4f77b',
        'outputs/01a17d39-9806-7153-9510-d82d1e7aaeea/classes/Bruxo_Pactos_e_Habilidades_Proposta_v01.html': 'bc6fdb0bcbd94eee423019c432b016ad8821a23756417c44fac09d36ae9f2ba9',
    }
    for name, digest in preserved.items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest, name
    qa = read('verificacao_propostas_v02.json')
    qa.update(integridade_dados=True, faces_gerais=30, distribuicao_xp={'1_xp': 9, 'meia_carta': 6, '2_xp': 3}, pdf_habilidades_existente_preservado=True, fenix_nucleo_preservado=True, cinco_pactos_anteriores_preservados=True, quinze_gerais_anteriores_preservadas=True, cobranca_fenix='Em aberto, sem nova decisão aplicada.')
    qa['revisao_mecanica'] = 'Leitura pelo agente principal e revisão independente dos quatro patronos e dos três pares gerais; não substitui partidas de teste.'
    qa['ajustes_apos_revisao'] = [
        'A cobrança do Trovão permite renunciar à recuperação normal para preservar a última Fadiga exigida.',
        'A descarga do Trovão exige Reação após um ataque inimigo concluído, distinguindo sua cadência da conservação do Inverno.',
        'Colher o Sonho exige alvo com Atormentado colocado pelo Bruxo antes de gerar a compra para a mão.',
        'Executar a Cláusula é pago antecipadamente e substitui somente uma carta inicial da defesa antes das compras adicionais.',
        'Patrono Presente oferece apenas uma resistência contestada por conjuração; Emprestar a Vontade não altera ataque nem defesa.',
    ]
    qa['revisao_visual'] = {'capturas_inspecionadas': ['previa_catalogo_bruxo_v02.png', 'previa_pacto_fenix_v02.png', 'previa_patrono_novo_v02.png', 'previa_habilidade_nova_celular_v02.png'], 'resultado': 'Texto legível, sem corte ou sobreposição nas capturas verificadas.'}
    qa['arquivos'] = []
    for relative in ['classes/dados/bruxo/novos_pactos_v02.json', 'classes/dados/bruxo/habilidades_gerais_v02.json', 'classes/dados/bruxo/regras_propostas_lote_v02.json', 'classes/dados/bruxo/contagem_habilidades_classes_v02.json', 'outputs/01a17d39-9806-7153-9510-d82d1e7aaeea/classes/Bruxo_Pactos_e_Habilidades_Proposta_v02.html']:
        qa['arquivos'].append({'caminho': relative, 'sha256': hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()})
    (DATA / 'verificacao_propostas_v02.json').write_text(json.dumps(qa, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'integridade': True, 'patronos': 10, 'gerais': 18, 'faces': 30}, ensure_ascii=False))


if __name__ == '__main__':
    main()
