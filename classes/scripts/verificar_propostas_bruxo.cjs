const { chromium } = require('C:/Users/Gamer/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const { pathToFileURL } = require('node:url');
const fs = require('node:fs/promises');
const path = require('node:path');

(async () => {
  const root=path.resolve(__dirname,'../..');
  const version=Number(process.argv[2]||2);
  if(![1,2,3].includes(version))throw new Error('Versão inválida');
  const suffix='v'+String(version).padStart(2,'0');
  const expectedPatrons=version>=2?10:5;
  const expectedSkills=version>=2?18:15;
  const expectedDetails=expectedPatrons+expectedSkills;
  const output=path.join(root,'outputs/01a17d39-9806-7153-9510-d82d1e7aaeea/classes');
  const file=path.join(output,'Bruxo_Pactos_e_Habilidades_Proposta_'+suffix+'.html');
  const browser=await chromium.launch({channel:'msedge',headless:true});
  try {
    const page=await browser.newPage({viewport:{width:1440,height:1100}});
    const errors=[];page.on('pageerror',e=>errors.push(e.message));
    await page.goto(pathToFileURL(file).href);
    const details=await page.locator('details').count();
    if(details!==expectedDetails)throw new Error('Esperados '+expectedDetails+' painéis de cartas, recebidos '+details);
    if(await page.locator('details.patron').count()!==expectedPatrons)throw new Error('Quantidade incorreta de patronos');
    if(await page.locator('details.general').count()!==expectedSkills)throw new Error('Quantidade incorreta de habilidades gerais');
    const ids=await page.locator('details').evaluateAll(els=>els.map(el=>el.id));
    if(version>=2&&(ids.some(id=>!id)||new Set(ids).size!==ids.length))throw new Error('IDs de cartas ausentes ou repetidos');
    await page.getByRole('button',{name:'Abrir todas as cartas'}).click();
    if(await page.locator('details[open]').count()!==expectedDetails)throw new Error('Expansão incompleta');
    const desktop=await page.evaluate(()=>({width:innerWidth,document:document.documentElement.scrollWidth,overflow:[...document.querySelectorAll('.panel')].filter(el=>el.scrollWidth>el.clientWidth+1).length}));
    if(desktop.document>desktop.width||desktop.overflow)throw new Error('Overflow no desktop: '+JSON.stringify(desktop));
    await page.locator(version>=2?'#BR-P00':'#BR-P01').screenshot({path:path.join(output,'previa_pacto_'+(version>=2?'fenix_'+suffix:'abismo')+'.png')});
    if(version>=2)await page.locator('#BR-P06').screenshot({path:path.join(output,'previa_patrono_novo_'+suffix+'.png')});
    await page.getByRole('button',{name:'Recolher as cartas'}).click();
    if(await page.locator('details[open]').count())throw new Error('Recolhimento incompleto');
    await page.screenshot({path:path.join(output,'previa_catalogo_bruxo'+(version>=2?'_'+suffix:'')+'.png')});
    await page.setViewportSize({width:480,height:900});
    await page.getByRole('button',{name:'Abrir todas as cartas'}).click();
    const mobile=await page.evaluate(()=>({width:innerWidth,document:document.documentElement.scrollWidth,overflow:[...document.querySelectorAll('.panel')].filter(el=>el.scrollWidth>el.clientWidth+1).length}));
    if(mobile.document>mobile.width||mobile.overflow)throw new Error('Overflow no celular: '+JSON.stringify(mobile));
    if(version>=2){
      await page.locator(version===3?'#BR-X03':'#BR-G09').screenshot({path:path.join(output,'previa_habilidade_nova_celular_'+suffix+'.png')});
      await page.emulateMedia({colorScheme:'dark'});
      const dark=await page.evaluate(()=>({width:innerWidth,document:document.documentElement.scrollWidth}));
      if(dark.document>dark.width)throw new Error('Overflow no tema escuro');
    }
    if(errors.length)throw new Error(errors.join('\n'));
    const qa={data:'2026-10-27',estado:'proposta_sem_playtest',versao:version,patronos:expectedPatrons,cartas_gerais:expectedSkills,paineis:details,abrir_e_recolher:true,ids_unicos:true,desktop,mobile,erros_javascript:errors,partidas_ou_simulacoes_de_equilibrio:false};
    await fs.writeFile(path.join(root,'classes/dados/bruxo/verificacao_propostas_'+suffix+'.json'),JSON.stringify(qa,null,2)+'\n');
    process.stdout.write(JSON.stringify(qa));
  } finally { await browser.close(); }
})().catch(e=>{process.stderr.write(e.stack);process.exitCode=1});
