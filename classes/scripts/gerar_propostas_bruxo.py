"""Gera o caderno de leitura dos pactos e habilidades propostos para o Bruxo."""
from pathlib import Path
import argparse, json, html, re
from html.parser import HTMLParser

ROOT=Path(__file__).resolve().parents[2]
DATA=ROOT/'classes/dados/bruxo'
e=lambda x:html.escape(str(x),quote=True)

def li(items):return '<ul>'+''.join('<li>'+e(x)+'</li>' for x in items)+'</ul>'
def field(title,text):return '<div class="field"><h4>'+e(title)+'</h4><p>'+e(text)+'</p></div>'

def render(version=3):
    suffix=f'v{version:02d}'
    out=ROOT/f'outputs/01a17d39-9806-7153-9510-d82d1e7aaeea/classes/Bruxo_Pactos_e_Habilidades_Proposta_{suffix}.html'
    rules=json.loads((DATA/f'regras_propostas_lote_{suffix}.json').read_text(encoding='utf-8'))
    pacts=json.loads((DATA/f'novos_pactos_{suffix}.json').read_text(encoding='utf-8'))
    skills=json.loads((DATA/f'habilidades_gerais_{suffix}.json').read_text(encoding='utf-8'))
    np=len(pacts['patronos']);nc=len(skills['cartas']);nf=sum(len(c['lados']) for c in skills['cartas'])
    rows=[];sections=[]
    labels={'escolha':'Escolha inicial','beneficio':'Bônus por cumprimento','cobranca':'Cobrança','quebra':'Descumprimento','reparacao':'Reparação','habilidade_inicial':'Habilidade concedida'}
    for p in pacts['patronos']:
        rows.append('<tr><td><a href="#'+e(p['id'])+'">'+e(p['nome'])+'</a><small>'+e(p['patrono'])+'</small></td><td>'+e(' · '.join(p['tags']))+'</td><td>'+e(p['ciclo'])+'</td></tr>')
        hero=p['heroi']
        limit='limite de Fadiga a definir' if hero['limite_fadiga'] is None else 'limite '+str(hero['limite_fadiga'])+' de Fadiga'
        h='<div class="panel"><div class="eyebrow">Carta 1 · Herói · '+e(limit)+'</div><h3>'+e(p['patrono'])+'</h3><p class="meta">Concede a tag Pacto</p>'+''.join(field(t,hero[k]) for t,k in [('Passiva','passiva'),('Ativada','ativada'),('Desencadeada','desencadeada'),('Crítico','critico')])+'</div>'
        contract='<div class="panel"><div class="eyebrow">Carta 2 · Pacto</div><h3>'+e(p['nome'])+'</h3><p class="tags">'+e(' · '.join(p['tags']))+'</p><p class="meta">Nível: 1 · 2 · 3 · 4 · 5<br>Começo da cena: 2N Pactos<br>Fim da cena: descarte a reserva<br>Progressão: cumprimento reconhecido pelo mestre</p>'+''.join(field(labels[k],v) for k,v in p['pacto'].items())+'</div>'
        spell='<div class="panel"><div class="eyebrow">Carta 3 · Habilidade inicial</div><p class="meta">Magias arcanas · Requer '+e(' · '.join(p['habilidade']['requer']))+'<br>Ataques mágicos usam foco e Espírito no dano. Testes contestados seguem o texto da face.</p>'
        for face in p['habilidade']['lados']:
            extra=''
            if version>=3 and 'conjuracao' in face:
                extra='<br>Conjuração: '+('sim' if face['conjuracao'] else 'não')+(' · Magia rápida' if face.get('rapida') else '')
            spell+='<div class="face"><h3>'+e(face['lado']+' · '+face['nome'])+'</h3><div class="meta">Limite '+str(face['limite_fadiga'])+' de Fadiga'+extra+'</div><p>'+e(face['texto'])+'</p></div>'
        spell+='</div>'
        pending='' if not p.get('pendencias') else '<div class="test"><h4>Definições em aberto</h4>'+li(p['pendencias'])+'</div>'
        status=p.get('rotulo_estado','Proposta para discussão e playtest')
        sections.append('<details class="patron" id="'+e(p['id'])+'"><summary><span>'+e(p['nome'])+'</span><small>'+e(p['papel'])+'</small></summary><div class="inside"><p class="meta">'+e(status)+'</p><p class="identity">'+e(p['identidade'])+'</p><p class="cycle">'+e(p['ciclo'])+'</p><div class="triple">'+h+contract+spell+'</div><div class="minor"><h4>Benefício de pacto menor — proposta</h4><p>'+e(p['menor'])+'</p><h4>Cobrança menor</h4><p>'+e(p['cobranca_menor'])+'</p></div>'+pending+'<div class="test"><h4>O que observar no playtest</h4><p>'+e(p['teste'])+'</p></div></div></details>')
    skill_sections=[]
    for xp,title in [(1,'Cartas de 1 XP'),(.5,'Meias cartas de ½ XP'),(2,'Cartas de 2 XP')]:
        cards=[]
        chosen=[x for x in skills['cartas'] if x['xp']==xp]
        if xp==1 and version>=2:
            group_order=list(skills['estrategias_1xp'])
            chosen.sort(key=lambda c:(group_order.index(c['grupo']),c['id']))
        previous_group=None
        for c in chosen:
            if xp==1 and version>=2 and c['grupo']!=previous_group:
                cards.append('<h3>'+e(c['grupo'])+'</h3>')
                previous_group=c['grupo']
            faces=''.join('<div class="panel"><h3>'+e(f['nome'])+'</h3><div class="meta">Limite '+str(f['limite_fadiga'])+' de Fadiga</div><p>'+e(f['texto'])+'</p></div>' for f in c['lados'])
            cards.append('<details class="general" id="'+e(c['id'])+'"><summary><span>'+e(c['nome'])+'</span><small>'+e(c['grupo'])+'</small></summary><div class="inside"><div class="double">'+faces+'</div></div></details>')
        skill_sections.append('<section><h2>'+title+'</h2><p class="meta">Requisito: Pacto. Custos de Pacto usam a reserva indicada no efeito ou a do pacto que concede a magia.</p>'+''.join(cards)+'</section>')
    css='''
:root{color-scheme:light dark;--bg:#f3f1ec;--paper:#fff;--ink:#292a2d;--muted:#62636b;--line:#dbd7ce;--accent:#704d86;--tint:#f3edf8}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.65 system-ui,sans-serif}main{max-width:1380px;margin:auto;padding:44px 28px 80px}header{max-width:1000px}h1{font-size:clamp(30px,4vw,46px);line-height:1.12;letter-spacing:-.025em}h2{font-size:28px;line-height:1.25;margin:0 0 14px}h3{font-size:19px;line-height:1.3;margin:6px 0 14px}h4{font-size:13px;text-transform:uppercase;letter-spacing:.05em;margin:15px 0 5px;color:var(--accent)}p{margin:8px 0 14px}.eyebrow{font-size:11px;font-weight:750;text-transform:uppercase;letter-spacing:.09em;color:var(--accent)}.status{background:var(--paper);border-left:4px solid var(--accent);padding:14px 18px}.meta,small{font-size:13px;color:var(--muted)}small{display:block}.tags{font-weight:650;color:var(--accent)}a{color:var(--accent)}section{margin-top:32px;padding:26px;background:var(--paper);border:1px solid var(--line);border-radius:12px}.rulegrid,.double{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px}.triple{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}.panel{border:1px solid var(--line);border-radius:9px;padding:19px;min-width:0;background:var(--paper)}.panel p{font-size:14px;line-height:1.65}.panel .meta{font-size:12px}.field p{margin-top:0}.face+.face{border-top:1px solid var(--line);padding-top:17px;margin-top:17px}.identity{font-size:19px;font-weight:600}.cycle{border-left:3px solid var(--accent);padding-left:13px;color:var(--accent)}details{border:1px solid var(--line);border-radius:10px;background:var(--paper);margin:14px 0;scroll-margin-top:15px}summary{cursor:pointer;padding:17px 21px;font-weight:700}summary::marker{color:var(--accent)}summary span{font-size:18px}summary small{font-weight:400;margin-left:18px}.inside{padding:0 22px 22px}.minor,.test{padding:12px 18px;margin-top:15px;border-radius:8px;background:var(--tint)}.test{background:var(--bg)}.minor p,.test p{font-size:14px}table{border-collapse:collapse;width:100%;font-size:14px}th,td{text-align:left;vertical-align:top;padding:14px 12px;border-bottom:1px solid var(--line)}th{font-size:12px;text-transform:uppercase;color:var(--muted)}td:first-child{width:30%;font-weight:650}td:nth-child(2){width:16%}.tablewrap{overflow:auto}li{margin:8px 0}.actions{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}.actions button{font:inherit;font-size:13px;padding:8px 13px;color:var(--ink);background:var(--paper);border:1px solid var(--line);border-radius:20px;cursor:pointer}footer{font-size:13px;color:var(--muted);margin-top:30px}@media(max-width:1000px){.triple{grid-template-columns:1fr}.rulegrid{grid-template-columns:1fr}}@media(max-width:650px){main{padding:24px 14px}.double{grid-template-columns:1fr}section{padding:20px 15px}.inside{padding:0 15px 18px}}@media(prefers-color-scheme:dark){:root{--bg:#19171d;--paper:#24212a;--ink:#ece7ef;--muted:#beb4c6;--line:#49414f;--accent:#d4a8e8;--tint:#34283e}}@media print{body{background:white;color:black}main{max-width:none;padding:0}.actions{display:none}details{display:block}details>summary{display:block}.inside{display:block!important}.triple,.double,.rulegrid{display:block}.panel{break-inside:avoid;margin-bottom:12px}section{break-before:page;border:0;padding:12px 0}}
'''
    common='<section><h2>Base de construção</h2><div class="rulegrid"><div><h3>Definições já confirmadas</h3>'+li(rules['base_confirmada'])+'</div><div><h3>Convenções propostas para este lote</h3>'+li(rules['convencoes_propostas'])+'</div></div></section>'
    if version>=3:
        common+='<section><h2>Ajustes aplicados nesta revisão</h2><p>Estas definições atualizam as convenções do lote anterior. A entrada da Fênix permanece integralmente preservada.</p>'+li(rules['ajustes_aplicados'])+'</section>'
    fenix_note='A Fênix está incluída com o núcleo já confirmado; sua cobrança continua em aberto.' if version>=2 else 'A Fênix continua como referência já desenvolvida: mortes, Fogo e recuperação. Sua cobrança permanece em aberto.'
    overview='<section><h2>Patronos e maneiras de jogar</h2><div class="tablewrap"><table><thead><tr><th>Pacto e patrono</th><th>Tags</th><th>Ciclo de jogo</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table></div><p class="meta">'+fenix_note+'</p></section>'
    comparison=''
    if version>=2:
        counts=skills['comparacao_quantidade']
        count_rows=''.join('<tr><td>'+e(row['classe'])+'</td><td>'+str(row['cartas_1xp'])+'</td><td>'+str(row['meias_05xp'])+'</td><td>'+str(row['cartas_2xp'])+'</td><td>'+str(row['entradas'])+'</td><td>'+str(row['faces'])+'</td></tr>' for row in counts['classes'])
        comparison='<section><h2>Habilidades gerais: mesma quantidade das outras classes</h2><p>'+e(counts['resumo'])+'</p><div class="tablewrap"><table><thead><tr><th>Classe</th><th>1 XP · A/B</th><th>½ XP · meia</th><th>2 XP · A/B</th><th>Entradas</th><th>Faces</th></tr></thead><tbody>'+count_rows+'</tbody></table></div><p class="meta">'+e(counts['criterio'])+'</p><p>'+e(counts['adicoes'])+'</p></section>'
    script="document.querySelectorAll('[data-expand]').forEach(b=>b.addEventListener('click',()=>{const open=b.dataset.expand==='yes';document.querySelectorAll('details').forEach(d=>d.open=open)}));document.querySelectorAll('a[href^=\"#\"]').forEach(a=>a.addEventListener('click',()=>{const target=document.getElementById(a.hash.slice(1));if(target&&target.tagName==='DETAILS')target.open=true}));"
    heading='Dez patronos.<br>Dez formas de pagar pelo poder.' if version>=2 else 'Cinco patronos.<br>Cinco formas de pagar pelo poder.'
    status_text=(f'Catálogo de {np} pactos, incluindo a Fênix, e {nc} habilidades gerais. A Fênix preserva seu núcleo confirmado. Os demais patronos, habilidades gerais e convenções adicionais são propostas para discussão e playtest.' if version>=2 else 'Este caderno traz cinco pactos novos, cada um com suas três cartas, e quinze cartas gerais. Valores, cobranças e regras adicionais deste lote ainda não foram aprovados. As definições confirmadas do Bruxo e da Fênix estão identificadas à parte.')
    if version>=3:
        status_text=f'Revisão aplicada conforme autorização do autor: {np} pactos e {nc} habilidades gerais. Os efeitos aprovados da Fênix permanecem como estavam e sua cobrança continua em aberto. Valores de equilíbrio seguem em playtest.'
    old_minor='' if version>=2 else '<section><h2>Opção menor da Fênix</h2><p>'+e(pacts['fenix_menor']['beneficio'])+'</p><p class="meta">'+e(pacts['fenix_menor']['cobranca'])+'</p></section>'
    document='<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Bruxo — '+str(np)+' pactos e '+str(nc)+' habilidades</title><style>'+css+'</style></head><body><main><header><div class="eyebrow">Sistema 21 · Bruxo · Proposta '+suffix+'</div><h1>'+heading+'</h1><p class="status">'+e(status_text)+'</p><p>O repertório de cada vínculo permanece estreito. A potência vem de escolher como cumprir, quando gastar a reserva e qual preço aceitar.</p><div class="actions"><button type="button" data-expand="yes">Abrir todas as cartas</button><button type="button" data-expand="no">Recolher as cartas</button></div></header>'+overview+common+'<section><h2>As três cartas de cada pacto</h2><p>Abra um pacto para consultar herói, contrato, habilidade inicial A/B, benefício menor e pontos de teste.</p>'+''.join(sections)+'</section>'+comparison+''.join(skill_sections)+old_minor+'<section><h2>Primeiros testes</h2>'+li(rules['testes_prioritarios'])+'<p class="meta">O lote passou por revisão de texto e interações. Não foram realizadas partidas nem simulações que comprovem equilíbrio numérico.</p></section><footer>Conjunto de trabalho em português do Brasil. Os pactos novos e habilidades gerais são propostas separadas das cartas já publicadas.</footer></main><script>'+script+'</script></body></html>'
    out.parent.mkdir(parents=True,exist_ok=True);out.write_text(document,encoding='utf-8');HTMLParser().feed(document)
    expected=(10,18,30) if version>=2 else (5,15,24)
    assert (np,nc,nf)==expected
    assert len({p['id'] for p in pacts['patronos']})==np
    assert len({c['id'] for c in skills['cartas']})==nc
    for p in pacts['patronos']:
        assert len(p['habilidade']['lados'])==2
        assert all(f['custo_fadiga']>=1 and f['limite_fadiga']>=f['custo_fadiga'] for f in p['habilidade']['lados'])
        assert all(p['heroi'][k] for k in ['passiva','ativada','desencadeada','critico'])
        assert all(p['pacto'][k] for k in ['beneficio','cobranca','quebra','reparacao'])
        assert p['menor'] and p['cobranca_menor']
    print(json.dumps({'relatorio':str(out),'patronos':np,'cartas_gerais':nc,'faces_gerais':nf,'estado':'proposta'},ensure_ascii=False))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--version',type=int,choices=[1,2,3],default=3)
    render(parser.parse_args().version)
