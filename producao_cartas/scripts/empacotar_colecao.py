import json,zipfile,sys,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'dados/catalogo_cartas.json').read_text(encoding='utf-8'))
TOTAL=len(data['cartas'])
assert len({c['id'] for c in data['cartas']})==TOTAL
VERSION=sys.argv[sys.argv.index('--version')+1] if '--version' in sys.argv else 'v01'
assert re.fullmatch(r'v\d{2}',VERSION)
output=ROOT/f'Sistema21_{TOTAL}_Artes_e_Dados_{VERSION}.zip'
assert all(c.get('imagem') and (ROOT/c['imagem']).is_file() for c in data['cartas'])
with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=1) as z:
    for card in data['cartas']:z.write(ROOT/card['imagem'],card['imagem'],compress_type=zipfile.ZIP_STORED)
    for name in ['catalogo_cartas.json','decisoes_fechadas.json','ajustes_autor.json','itens_adicionais.json','regras_pocoes_para_manual.json','comparacao_pocoes_witcher3_2026-10-27.json','prompts_lote_v01.json','prompts_geracao_piloto.json','prompt_corrente_v02.json','artes_lote_v01.json','artes_piloto.json','simbolos_colecao_v01.json','medidas_colecao_v01.json','qa_colecao_v01.json','imposicao_colecao_v01.json','estado_producao.json']:
        path=ROOT/'dados'/name
        if path.is_file():z.write(path,'dados/'+name)
    if VERSION!='v01':
        historico=[f'{prefix}_v{i:02d}.json' for i in range(2,int(VERSION[1:])+1) for prefix in ['prompts_revisao_armas','qa_revisao_armas','auditoria_alinhamento_armas']]
        for name in dict.fromkeys([f'medidas_colecao_{VERSION}.json',f'qa_colecao_{VERSION}.json',f'imposicao_colecao_{VERSION}.json','artes_revisadas.json',f'qa_ajuste_area_{VERSION}.json',f'regras_raras_aprovadas_{VERSION}.json',f'qa_regras_raras_{VERSION}.json',f'prompts_pocoes_{VERSION}.json',f'artes_pocoes_{VERSION}.json',f'geracoes_pocoes_{VERSION}.json',f'qa_expansao_final_{VERSION}.json']+historico):
            path=ROOT/'dados'/name
            if path.is_file():z.write(path,'dados/'+name)
    for name in ['montar_piloto.py','montar_colecao.py','verificar_colecao.py','montar_corrente.py']:
        z.write(ROOT/'scripts'/name,'scripts/'+name)
    z.write(ROOT/'dados/simbolos_piloto.json','dados/simbolos_piloto.json')
    revisao='\nRevisão v02: 10 espadas com proporções e alinhamento corrigidos; Gládio Inquietante mantido por decisão do autor. Prompts: dados/prompts_revisao_armas_v02.json.\n' if VERSION=='v02' else ''
    if VERSION=='v03':revisao='\nRevisão v03: mantém as 10 espadas corrigidas e alinha o Quebra-Elmos. Gládio Inquietante preservado. Corrente de Caça: EQ-156, páginas A4 35 e 36; páginas individuais 311 e 312. Prompts nas revisões v02 e v03.\n'
    if VERSION=='v04':revisao='\nRevisão v04: auditoria das 46 armas e de três focos com haste. Oito armas e o Cajado de Batalha foram alinhados nesta versão. Mantidas as 11 correções anteriores. Gládio preservado. Corrente de Caça: EQ-156, páginas A4 35 e 36; páginas individuais 311 e 312. Prompts e auditoria na pasta dados.\n'
    if VERSION=='v05':revisao='\nRevisão v05: Lança Trovejante atinge o alvo e todas as criaturas adjacentes, incluindo aliados; retorno de 3 de dano de Raio apenas ao usar a habilidade. Arco das Sombras exige começar Oculto para causar dano; gasta Sombra antes e recebe depois do ataque. Arco da Maré com área de 3 x 3 quadrados. Regras aprovadas pelo autor e artes da v04 preservadas. Corrente de Caça: EQ-156, páginas A4 35 e 36; páginas individuais 311 e 312.\n'
    if VERSION=='v06':revisao='\nRevisão v06: 170 itens; 14 novas poções EQ-157 a EQ-170, com artes individuais inéditas e fundo transparente. Ração de Viagem concede uma carta adicional na próxima mão inicial; Runa de Luz descarta Sombra em alcance curto; Amuleto de Kanil esclarece a última carta e a cura do aliado. Tag Poção nas 7 poções anteriores. Preservadas as artes anteriores, as 20 correções de armas e as regras raras da v05. Gládio mantido por decisão do autor; Corrente EQ-156 somente com elos. PDFs: 38 páginas A4 e 340 páginas individuais, todas as cartas com verso de consulta. Prompts exatos em dados/prompts_pocoes_v06.json; origem e hashes em dados/artes_pocoes_v06.json. Regras comuns das poções separadas para o manual em dados/regras_pocoes_para_manual.json.\n'
    z.writestr('LEIA_ME.txt',f'Sistema 21 / Masmorras\n{TOTAL} artes ativas, dados e prompts. Ferramenta de geração: image_gen.imagegen integrada.\nCorrente: versão aprovada v02, somente elos.\nOs scripts usam Python, ReportLab, Pillow, pypdf e pdfplumber e as fontes Arial/Georgia do Windows.\nImpressão dos PDFs: A4, 100%, sem ajustar à página, virar pela borda longa.\n'+revisao)
with zipfile.ZipFile(output) as z:
    assert sum(n.endswith('.png') for n in z.namelist())==TOTAL
print(json.dumps({'pacote':str(output),'artes':TOTAL,'bytes':output.stat().st_size},ensure_ascii=False))
