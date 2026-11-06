"""Gera data/equipamentos.json com os 170 equipamentos do Lucas (0.25).

Fontes (passe os caminhos como argumentos):
  1. economia.json  -> o bloco DATA do "Estudo_Economia_e_Precos" (nome, categoria, raridade,
                        habilidade, tags, campos, preço em cobre, mercado e revenda);
  2. ocupacao.json  -> a tabela "Os 170 itens" do "Inventario_por_Espacos" (ocupação e reserva).

Uso: python3 tools/gerar_equipamentos.py economia.json ocupacao.json data/equipamentos.json
"""
import json, re, sys, unicodedata

def slug(nome):
    s = unicodedata.normalize('NFKD', nome.lower())
    s = ''.join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r'[^a-z0-9]+', '_', s).strip('_')
    return s

ESPACOS = {'Armamentos e repertórios': 'armamentos', 'Consumíveis especiais': 'consumiveis', 'Mochila': 'mochila',
           'Acessórios': 'acessorios', 'Armadura': 'armadura', 'Pés': 'pes', 'Costas': 'costas', 'Cabeça': 'cabeca'}
# ids antigos que o jogo já usava e mudaram de nome
IDS = {'corda_15_m': 'corda'}

def main(eco, occ, saida):
    d = json.load(open(eco, encoding='utf-8'))
    o = json.load(open(occ, encoding='utf-8'))
    mercados = {m['codigo']: m for m in d['mercados']}
    itens, vistos = [], set()
    for x in d['itens']:
        oc = o[x['id']]
        assert oc['nome'] == x['nome'], (oc['nome'], x['nome'])
        m = re.match(r'(\d+) (.+?)( \+ 1 (.+))?$', oc['ocupa'])
        qtd, esp, extra = int(m.group(1)), m.group(2), m.group(4) or ''
        reserva = oc['reserva']
        rid = IDS.get(slug(x['nome']), slug(x['nome']))
        assert rid not in vistos, rid
        vistos.add(rid)
        item = {
            'eq': x['id'], 'id': rid, 'nome': x['nome'], 'categoria': x['categoria'], 'raridade': x['raridade'],
            'tags': x['tags'], 'campos': x['campos'], 'habilidade': x['habilidade'].strip(),
            'preco_cobre': int(round(x['preco_cobre'])), 'mercado': x['mercado'],
            'revenda': mercados[x['mercado']]['revenda'],
            'espaco': ESPACOS[esp], 'ocupa': qtd,
        }
        if extra.startswith('Amuletos'):
            item['amuleto'] = True
        if extra == 'Costas':
            item['tambem_costas'] = True
        r = re.match(r'(\d+) Mochila', reserva)
        if r:
            item['reserva_mochila'] = int(r.group(1))
        if 'até 3' in reserva or 'Até 3' in oc['obs']:
            item['pacote'] = 3
        itens.append(item)
    out = {'fonte': 'Estudo_Economia_e_Precos_v01 + Inventario_por_Espacos_v01 (27/10/2026)',
           'moedas': {'cobres_por_prata': d['parametros']['cobres_por_prata'], 'pratas_por_ouro': d['parametros']['pratas_por_ouro']},
           'mercados': d['mercados'], 'itens': itens}
    json.dump(out, open(saida, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(len(itens), 'itens ->', saida)

if __name__ == '__main__':
    main(*sys.argv[1:4])
