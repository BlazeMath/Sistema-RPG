import json,re,sys
from pathlib import Path
import openpyxl

ROOT=Path(__file__).resolve().parents[2]
PROD=ROOT/'producao_cartas'
SRC=ROOT/'outputs/revisao_itens_2026-10-26/Sistema21_Revisao_dos_155_Itens.xlsx'
wb=openpyxl.load_workbook(SRC,read_only=True,data_only=False)
style='Ilustração de fantasia medieval sombria, pintada digitalmente com acabamento semirrealista e pinceladas discretas. Materiais fisicamente críveis, silhueta clara, detalhes seletivos para leitura em carta pequena. Um único equipamento isolado, sem pessoa, mão ou cenário. Luz principal quente suave pela esquerda e recorte frio sutil; cores naturais pouco saturadas. Objeto inteiro visível, centralizado, com margem livre em todos os lados. Fundo realmente transparente. Sem letras, números, marcas, molduras, interface ou texto.'
descriptions={
 'EQ-001':'Uma faca utilitária medieval comum, lâmina curta de aço fosco de um só gume e ponta levemente curva, cabo gasto de madeira e couro marrom. Design simples, funcional, com sinais discretos de uso. Faca diagonal inteira, sem bainha, sem ornamento mágico.',
 'EQ-010':'Um estilete medieval incomum: adaga perfurante de lâmina muito fina, rígida, longa e pontiaguda, seção triangular, pequena guarda de aço e cabo escuro bem acabado. Elegância sóbria e precisão; sem efeito mágico e sem segunda arma.',
 'EQ-156':'Uma corrente de caça de combate medieval formada somente por grossos elos ovais de ferro escurecido realmente conectados. Duas pontas livres, cada uma terminando em um elo normal. Corrente em curva aberta. Sem empunhadura, couro, peso, lâmina, gancho, fogo ou acessórios nas pontas.',
 'EQ-046':'Um gibão de armadura leve de couro marrom curtido e usado, vazio, sem corpo nem manequim visível. Dobras práticas, costuras reforçadas e uma discreta costura de bolso oculto no forro; proteção flexível de batedor. Vista de três quartos, peça inteira, sem armadura metálica pesada.',
 'EQ-060':'Um grande scutum retangular de legião de fantasia medieval, corpo de madeira curvo revestido de couro vermelho escuro gasto, borda de metal escurecido, boss central de bronze e discretas linhas geométricas douradas sem letras. Equipamento raro de formação, sólido e largo. Escudo inteiro em três quartos; sem pessoa nem outro escudo.',
 'EQ-061':'Uma pequena poção de cura medieval: frasco compacto de vidro espesso com líquido rubi translúcido, tampa de cortiça e um cordão simples de couro. Design comum e prático, vidro artesanal irregular muito legível, sem rótulo, sem palavras e sem objetos ao redor.',
 'EQ-116':'Uma varinha arcana medieval de madeira escura, com um único cristal de quartzo facetado claro preso à ponta por uma montagem discreta de prata envelhecida. Brilho mágico muito sutil no cristal, sem associar a um elemento específico. Varinha inteira em diagonal, sem mão e sem outros objetos.',
 'EQ-127':'Uma única pedra de runa de fogo consumível, pequena peça de basalto escuro com sulcos gravados formando um símbolo abstrato de chama, sem qualquer alfabeto ou escrita. Um brilho âmbar suave sai dos sulcos; bordas de pedra gastas e textura legível. Pedra inteira isolada.',
 'EQ-139':'Um grimório elemental de fogo medieval fechado, livro grosso de couro castanho muito escuro, cantos de cobre envelhecido, fecho de metal e um símbolo abstrato de chama na capa, sem letras. Pequenos sinais de calor no couro e luz âmbar discretíssima no símbolo. Livro inteiro em três quartos, sem fogo espalhado nem cenário.',
}
pilot=list(descriptions)
cards=[]
for row in wb['Revisão dos Itens'].iter_rows(min_row=7,values_only=True):
    if not row[0]:continue
    fields={}
    for line in (row[2] or '').splitlines():
        if ':' in line:
            k,v=line.split(':',1);fields[k.strip()]=v.strip()
    name,category=str(row[1]).split('\n',1)
    cards.append({'id':row[0],'nome':name,'categoria':category,'campos':fields,'tags':(row[3] or '').split(' · '),'habilidade':row[4] or '',
                  'revisao':row[5] or '', 'fonte':row[7] or '', 'piloto':row[0] in pilot,
                  'imagem':f'artes/piloto/{row[0]}_v01.png' if row[0] in pilot else None})
registry_path=PROD/'dados/artes_piloto.json'
if registry_path.exists():
    registry=json.loads(registry_path.read_text(encoding='utf-8'))
    for card in cards:
        asset=registry.get(card['id'],{}).get('arquivo')
        if asset and Path(asset).is_file():card['imagem']=Path(asset).relative_to(PROD).as_posix()
bulk_registry=PROD/'dados/artes_lote_v01.json'
if bulk_registry.exists():
    bulk={r['id']:r for r in json.loads(bulk_registry.read_text(encoding='utf-8'))}
    for card in cards:
        asset=bulk.get(card['id'],{}).get('arquivo')
        if asset and (PROD/asset).is_file():card['imagem']=asset
revision_registry=PROD/'dados/artes_revisadas.json'
if revision_registry.exists():
    revisions={r['id']:r for r in json.loads(revision_registry.read_text(encoding='utf-8'))}
    for card in cards:
        asset=revisions.get(card['id'],{}).get('arquivo')
        if asset and (PROD/asset).is_file():card['imagem']=asset
layout_path=PROD/'dados/classificacao_layout.json'
if layout_path.exists():
    layouts={r['id']:r['modo'] for r in json.loads(layout_path.read_text(encoding='utf-8'))}
    for card in cards:card['diagramacao']=layouts.get(card['id'],'a_classificar')
assert len(cards)==156 and len({c['id'] for c in cards})==156
additional_path=PROD/'dados/itens_adicionais.json'
if additional_path.exists():
    additional=json.loads(additional_path.read_text(encoding='utf-8'))
    assert not ({c['id'] for c in cards}&{c['id'] for c in additional}), 'IDs adicionais repetidos'
    cards.extend(additional)
    assert len({c['id'] for c in cards})==len(cards)
data={'projeto':'Sistema 21 — Masmorras','fonte':str(SRC),'base_mecanica':r'C:\Users\Gamer\Downloads\Equipamentos_Cartas_incompleto.pdf','cartas':cards,
      'piloto':pilot,'direcao_arte':style,'decisoes_pendentes':{
          'resistencia_gelo':'Valor de resistência de Respiração Flamejante: aguardando resposta.',
          'ficha_gelo':'Remoção de ficha de Gelo pela Runa de Fogo: aguardando resposta.',
          'flanqueamento':'Cláusula de flanqueamento do Scutum: aguardando resposta.'}}
decision_path=PROD/'dados/decisoes_fechadas.json'
if decision_path.exists():
    decisions=json.loads(decision_path.read_text(encoding='utf-8'))
    fire=next(c for c in cards if c['id']=='EQ-139')
    fire['habilidade']=fire['habilidade'].replace('ganha resistência a ataques de Gelo','ganha resistência 2 contra dano de Gelo')
    assert 'resistência 2' in fire['habilidade']
    fire['revisao']='Decisão do autor: Respiração Flamejante concede resistência 2 a Gelo durante a cena. Valores e demais efeitos do PDF preservados.'
    next(c for c in cards if c['id']=='EQ-127')['revisao']='Mantida a opção que remove ficha de Gelo. Decisão do autor: uma ficha de Gelo reduz o movimento em 1; a regra estará no manual.'
    next(c for c in cards if c['id']=='EQ-060')['revisao']='Mantida a proteção contra flanqueamento, cuja regra estará no manual. Definições comuns continuam fora da carta.'
    data['decisoes_fechadas']=decisions
    data['decisoes_pendentes']={}
author_adjustments=PROD/'dados/ajustes_autor.json'
if author_adjustments.exists():
    adjustments=json.loads(author_adjustments.read_text(encoding='utf-8'))
    for card in cards:
        card.update(adjustments.get(card['id'],{}))
(PROD/'dados/catalogo_cartas.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
prompts=[{'id':i,'nome':next(c['nome'] for c in cards if c['id']==i),'prompt':f'Use case: stylized-concept. Asset type: standalone collectible RPG equipment illustration. {style}\nObjeto: {d}','transparent_background':True,'status':'a gerar'} for i,d in descriptions.items()]
(PROD/'dados/prompts_piloto.json').write_text(json.dumps(prompts,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Catálogo: {len(cards)} itens. Piloto: 9 imagens. Direção de arte e prompts registrados.')
