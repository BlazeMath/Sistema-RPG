import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Workbook, SpreadsheetFile } from '@oai/artifact-tool';

const out=path.dirname(fileURLToPath(import.meta.url));
const model=JSON.parse(await fs.readFile(path.join(out,'modelo_economico_v01.json'),'utf8'));
const wb=Workbook.create();
const prices=wb.worksheets.add('Preços');
const economy=wb.worksheets.add('Economia');
const refs=wb.worksheets.add('Referências');
const ink='#29261F',brown='#4C3C2D',muted='#716A5D',paper='#FFFDF7',amber='#FFF0C2';
for(const [s,range] of [[prices,'A1:T177'],[economy,'A1:M45'],[refs,'A1:H54']]){
 s.showGridLines=false;
 s.getRange(range).format.font={name:'Arial',size:10,color:ink};
 s.getRange(range).format.verticalAlignment='center';
 s.getRange(range).format.rowHeight=23;
}
prices.tabColor=brown;economy.tabColor='#A3875D';
function cell(s,a,v){s.getRange(a).values=[[v]];}
function form(s,a,v){s.getRange(a).formulas=[[v]];}
function title(s,t){cell(s,'A2',t);s.getRange('A2').format.font={name:'Arial',size:15,bold:true,color:brown};s.getRange('A2:M2').format.borders={bottom:{style:'thin',color:'#B79B64'}};s.getRange('A2:M2').format.rowHeight=29;}
function header(s,r){s.getRange(r).format={fill:brown,font:{name:'Arial',size:10,color:'#FFFFFF',bold:true},horizontalAlignment:'center',verticalAlignment:'center',wrapText:true,rowHeight:36};}

title(economy,'Moeda, mercado e orçamento de referência');
economy.getRange('A4:C4').values=[['Parâmetro','Valor','Unidade ou interpretação']];header(economy,'A4:C4');
economy.getRange('A5:C13').values=[
 ['Cobres por prata',10,'Conversão proposta'],['Pratas por ouro',100,'Conversão proposta'],['Diária de trabalhador',20,'Cobre por dia remunerado; valor bruto'],['Multiplicador de mercado',1,'Ajusta os preços, mantendo salários'],['Diária de artesão',60,'Cobre por dia remunerado'],['Dias remunerados no ano',250,'Hipótese de escala, sem impor calendário de trabalho'],['Cobres por ouro',null,'Conversão calculada'],['Ouro em diárias de trabalhador',null,'Poder de compra bruto, sem despesas'],['Renda anual bruta de trabalhador',null,'Ouro; não poupança e não renda familiar']
];
form(economy,'B11','=B5*B6');form(economy,'B12','=B11/B7');form(economy,'B13','=B7*B10/B11');
economy.getRange('B5:B10').format.fill=amber;
economy.getRange('B5:B13').setNumberFormat('0.00');
economy.getRange('B8').setNumberFormat('0.00"×"');
economy.getRange('C5:C13').format.wrapText=true;
economy.getRange('A5:C13').format.rowHeight=36;
cell(economy,'A15','Células amarelas: premissas editáveis. Todos os valores são propostas do estudo.');
economy.getRange('A15:H15').format.rowHeight=27;
economy.getRange('A15').format.font={name:'Arial',size:10,italic:true,color:muted};

cell(economy,'A18','Orçamento de uma missão inicial');
economy.getRange('A18:C18').format.font={name:'Arial',size:11,bold:true,color:brown};
economy.getRange('A19:C19').values=[['Premissa ou resultado','Valor','Unidade ou hipótese']];header(economy,'A19:C19');
economy.getRange('A20:C28').values=[['Heróis no grupo',4,'Pessoas'],['Pagamento do contrato',120,'Prata; proposta, sem atualizar o protótipo'],['Saque vendido',24,'Prata; hipótese ilustrativa, não receita garantida'],['Duração da missão',2,'Dias de calendário'],['Estalagem por herói',5,'Prata por descanso atendido'],['Rações consumidas',4,'Unidades da carta EQ-064'],['Poções de cura consumidas',2,'Doses de EQ-061'],['Poções de mana consumidas',1,'Doses de EQ-068'],['Tochas consumidas',4,'Unidades de EQ-062']];
economy.getRange('B20:B28').format.fill=amber;economy.getRange('B20:B28').setNumberFormat('0.0');
const lookup=(id,col='F')=>`INDEX('Preços'!$${col}$8:$${col}$177,MATCH("${id}",'Preços'!$A$8:$A$177,0))`;
const budget=[['Pousada do grupo','=B20*B24','Prata'],['Rações',`=B25*${lookup('EQ-064')}`,'Prata'],['Cura',`=B26*${lookup('EQ-061')}`,'Prata'],['Mana',`=B27*${lookup('EQ-068')}`,'Prata'],['Tochas',`=B28*${lookup('EQ-062')}`,'Prata'],['Despesas totais','=SUM(B31:B35)','Prata'],['Excedente do grupo','=SUM(B21:B22)-B36','Prata, antes de outros gastos e perdas'],['Excedente por herói','=B37/B20','Prata'],['Espada Longa',`=${lookup('EQ-005')}`,'Prata'],['Missões para a espada','=IF(B38>0,ROUNDUP(B39/B38,0),"sem excedente")','Comprando sem crédito e mantendo o mesmo excedente'],['Arnês de Placas',`=${lookup('EQ-048')}`,'Prata'],['Missões para o arnês','=IF(B38>0,ROUNDUP(B41/B38,0),"sem excedente")','Ilustração; não impõe progressão por compra']];
economy.getRange('A31:C42').values=budget.map(x=>[x[0],null,x[2]]);
economy.getRange('B31:B42').formulas=budget.map(x=>[x[1]]);
economy.getRange('B31:B42').setNumberFormat('0.00');
economy.getRange('B40').setNumberFormat('0');economy.getRange('B42').setNumberFormat('0');
economy.getRange('A36:C38').format.fill='#EEE5D5';economy.getRange('A36:C38').format.font.bold=true;
economy.getRange('C20:C42').format.wrapText=true;economy.getRange('A20:C42').format.rowHeight=35;

economy.getRange('E4:H4').values=[['Vida civil proposta','Prata','Unidade','Contexto']];header(economy,'E4:H4');
economy.getRange('E5:H15').values=model.vida_civil;
form(economy,'F11','=B7/B5');form(economy,'F12','=B9/B5');
economy.getRange('E5:H15').format.rowHeight=43;economy.getRange('H5:H15').format.wrapText=true;
economy.getRange('F5:F15').setNumberFormat('0.00');
economy.getRange('J4:M4').values=[['Acesso','Faixa baixa','Faixa alta','Revenda']];header(economy,'J4:M4');
economy.getRange('J5:M9').values=model.mercados.map(m=>[m.nome,m.min,m.max,m.revenda]);
economy.getRange('K5:M9').setNumberFormat('0%');economy.getRange('K5:M9').format.fill=amber;
cell(economy,'J11','Faixas são parâmetros de negociação, não intervalos estatísticos.');cell(economy,'J13','Revenda requer comprador adequado, autenticidade e caixa disponível.');
economy.getRange('J11').format.wrapText=false;
economy.getRange('J13').format.wrapText=false;
for(const [col,w] of Object.entries({A:34,B:15,C:49,D:3,E:26,F:12,G:22,H:57,I:3,J:23,K:13,L:13,M:13}))economy.getRange(`${col}1:${col}45`).format.columnWidth=w;

title(prices,'Preços propostos dos 170 equipamentos');
cell(prices,'A4','Mercado abastecido; item íntegro e identificado. Preços propostos para revisão e playtest.');
cell(prices,'A5','Raridades originais preservadas. Suporte comum e prêmio são estimativas de design; detalhes à direita.');
prices.getRange('A4:T5').format.font={name:'Arial',size:10,italic:true,color:muted};
const heads=['ID','Item','Categoria','Raridade da carta','Unidade','Compra em prata','Compra em ouro','Faixa baixa em prata','Faixa alta em prata','Revenda em prata','Diárias brutas','Acesso','Suporte comum em cobre','Prêmio especial em cobre','Faixa baixa','Faixa alta','Fator revenda','Materiais de referência','Justificativa do valor','Ressalva da regra'];
prices.getRange('A7:T7').values=[heads];
prices.getRange('A8:T177').values=model.itens.map(i=>[i.id,i.nome,i.categoria,i.raridade,i.unidade,null,null,null,null,null,null,i.mercado_nome,i.suporte_cobre,i.premio_cobre,null,null,null,i.materiais_estimados,i.justificativa,i.ressalva]);
prices.getRange('F8:K177').formulas=model.itens.map((i,idx)=>{const r=idx+8;return [`=ROUND((M${r}+N${r})*'Economia'!$B$8,0)/'Economia'!$B$5`,`=F${r}/'Economia'!$B$6`,`=MAX(1,ROUND(F${r}*'Economia'!$B$5*O${r},0))/'Economia'!$B$5`,`=MAX(1,ROUND(F${r}*'Economia'!$B$5*P${r},0))/'Economia'!$B$5`,`=ROUNDDOWN(ROUND(F${r}*'Economia'!$B$5*Q${r},8),0)/'Economia'!$B$5`,`=F${r}*'Economia'!$B$5/'Economia'!$B$7`];});
prices.getRange('O8:Q177').formulas=model.itens.map((i,idx)=>{const r=idx+8;return ['K','L','M'].map(col=>`=INDEX('Economia'!$${col}$5:$${col}$9,MATCH(L${r},'Economia'!$J$5:$J$9,0))`);});
const table=prices.tables.add('A7:T177',true,'PrecosEquipamentos');table.style='TableStyleLight15';table.showFilterButton=true;
header(prices,'A7:T7');prices.getRange('A7:T7').format.rowHeight=43;
prices.getRange('F8:J177').setNumberFormat('#,##0.00');prices.getRange('G8:G177').setNumberFormat('0.0000');prices.getRange('K8:K177').setNumberFormat('0.0');
prices.getRange('M8:N177').setNumberFormat('#,##0');prices.getRange('O8:Q177').setNumberFormat('0%');
prices.getRange('A8:T177').format.borders={insideVertical:{style:'thin',color:'#FFFFFF'},insideHorizontal:{style:'thin',color:'#E3DED4'},top:{style:'thin',color:'#E3DED4'},bottom:{style:'thin',color:'#E3DED4'},left:{style:'thin',color:'#FFFFFF'},right:{style:'thin',color:'#FFFFFF'}};
prices.getRange('A8:T177').format.fill='#FFFFFF';
for(let r=8;r<=177;r+=2)prices.getRange(`A${r}:T${r}`).format.fill='#F7F3EA';
prices.getRange('M8:N177').format.fill='#FFF7DF';
prices.getRange('A8:T177').format.rowHeight=31;
for(const c of ['B','C','D','E','R','S','T'])prices.getRange(`${c}8:${c}177`).format.wrapText=true;
prices.getRange('F8:K177').format.horizontalAlignment='right';prices.getRange('M8:Q177').format.horizontalAlignment='right';
prices.getRange('F8:F177').format.font.bold=true;
prices.getRange('D8:D177').conditionalFormats.add('containsText',{text:'RARA',format:{fill:'#F0E3BE',font:{color:'#6B4C12',bold:true}}});
prices.getRange('D8:D177').conditionalFormats.add('containsText',{text:'Não informada',format:{font:{color:'#716A5D',italic:true}}});
for(const [col,w] of Object.entries({A:10,B:34,C:23,D:17,E:21,F:14,G:14,H:15,I:15,J:15,K:15,L:16,M:17,N:18,O:13,P:13,Q:14,R:44,S:88,T:78}))prices.getRange(`${col}1:${col}177`).format.columnWidth=w;
prices.freezePanes.freezeRows(7);prices.freezePanes.freezeColumns(2);

title(refs,'Referências e medidas comparáveis');
cell(refs,'A4','Valores das obras ficam na moeda original. Não existe conversão real entre universos.');
refs.getRange('A6:H6').values=[['Medida','Recorte','Bem ou parâmetro','Valor','Unidade original','Contexto','Fonte','Localizador']];header(refs,'A6:H6');
const sourceMap=Object.fromEntries(model.fontes.fontes.map(s=>[s.id,s]));
refs.getRange('A7:H31').values=model.fontes.medidas.map(m=>[m.codigo,m.recorte,m.medida,m.valor,m.unidade,m.contexto,m.fonte,sourceMap[m.fonte].localizador]);
refs.getRange('D7:D31').setNumberFormat('#,##0.00');refs.getRange('A7:H31').format.rowHeight=50;
refs.getRange('B7:C31').format.wrapText=true;refs.getRange('E7:F31').format.wrapText=true;refs.getRange('H7:H31').format.wrapText=true;
cell(refs,'A34','Fontes e condição de uso dos dados');
refs.getRange('A36:H36').values=[['Fonte','Universo','Documento','Natureza','Endereço ou arquivo','Localizador','Observação','Consulta']];header(refs,'A36:H36');
refs.getRange('A37:H46').values=model.fontes.fontes.map(s=>[s.id,s.universo,s.titulo,s.tipo,s.url||s.arquivo,s.localizador,s.nota,'27/10/2026']);
refs.getRange('B37:G46').format.wrapText=true;refs.getRange('A37:H46').format.rowHeight=80;
cell(refs,'A49','Comparações em diárias brutas');
refs.getRange('A50:E50').values=[['Referência','Cálculo','Resultado','Unidade','Limitação']];header(refs,'A50:E50');
refs.getRange('A51:E54').values=[['D&D: Espada Longa','15 GP / 0,2 GP',null,'diárias','Preço de contratado sem treino'],['D&D: Placas','1.500 GP / 0,2 GP',null,'diárias','Não converter o resultado em anos de poupança'],['Inglaterra: espada barata','6d / 1,25d',null,'diárias','Anos 1340; qualidade inferior'],['Inglaterra: armadura milanesa','2.000d / 4d',null,'diárias','1441 e salário médio de 1441–1450']];
refs.getRange('C51:C54').formulas=[['=D25/D23'],['=D26/D23'],['=D28/D29'],['=D30/D31']];
refs.getRange('C51:C54').setNumberFormat('#,##0.0');refs.getRange('A51:E54').format.rowHeight=40;refs.getRange('A51:B54').format.wrapText=true;refs.getRange('E51:E54').format.wrapText=true;
for(const [col,w] of Object.entries({A:14,B:30,C:42,D:17,E:58,F:53,G:65,H:55}))refs.getRange(`${col}1:${col}54`).format.columnWidth=w;
refs.freezePanes.freezeRows(6);

// Entradas positivas evitam que ausência de unidade ou salário produza um preço plausível.
for(const a of ['B5:B7','B9:B10'])economy.getRange(a).dataValidation={rule:{type:'decimal',operator:'greaterThan',formula1:0}};
economy.getRange('B8').dataValidation={rule:{type:'decimal',operator:'greaterThan',formula1:0}};
prices.getRange('M8:N177').dataValidation={rule:{type:'decimal',operator:'greaterThanOrEqual',formula1:0}};

wb.recalculate();
const key=await wb.inspect({kind:'table',range:'Economia!A31:C42',include:'values,formulas',tableMaxRows:12,tableMaxCols:3,maxChars:3500});
console.log(key.ndjson);
const errs=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:50},summary:'Verificação de fórmulas',maxChars:1500});console.log(errs.ndjson);
const actual=prices.getRange('F8:K177').values;
for(let n=0;n<model.itens.length;n++){
 const i=model.itens[n],a=actual[n];
 for(const [j,v] of [[0,i.preco_prata],[1,i.preco_ouro],[2,i.faixa_baixa_prata],[3,i.faixa_alta_prata],[4,i.revenda_prata],[5,i.dias_salario_bruto]]){
  if(typeof a[j]!=='number'||Math.abs(a[j]-v)>0.00001)throw Error(`Diferença ${i.id} col ${j}: ${a[j]} versus ${v}`);
 }
}
// Verifica reação a um parâmetro e restaura o mesmo modelo antes da entrega.
const base=prices.getRange('F12').values[0][0];
cell(economy,'B8',1.25);wb.recalculate();
if(Math.abs(prices.getRange('F12').values[0][0]-base*1.25)>.001)throw Error('Multiplicador não recalculou');
cell(economy,'B8',1);wb.recalculate();
if(Math.abs(prices.getRange('F12').values[0][0]-base)>.001)throw Error('Restauração não recalculou');
cell(economy,'B21',0);cell(economy,'B22',0);wb.recalculate();
if(economy.getRange('B40').values[0][0]!=='sem excedente'||economy.getRange('B42').values[0][0]!=='sem excedente')throw Error('Orçamento sem receita não foi tratado');
cell(economy,'B21',120);cell(economy,'B22',24);wb.recalculate();
if(Math.abs(economy.getRange('B38').values[0][0]-19.8)>.0001)throw Error('Orçamento não foi restaurado');
for(const [sheetName,range,name] of [['Preços','A1:L13','precos_inicio'],['Preços','R7:T12','justificativas'],['Economia','A1:H15','moeda_vida_civil'],['Economia','A18:C42','orcamento'],['Referências','A1:H12','referencias'],['Referências','A49:E54','normalizacoes']]){
 const p=await wb.render({sheetName,range,scale:1.5,format:'png'});
 await fs.writeFile(path.join(out,name+'.png'),new Uint8Array(await p.arrayBuffer()));
}
const xlsx=await SpreadsheetFile.exportXlsx(wb);await xlsx.save(path.join(out,'Tabela_Precos_170_Itens_Estudo_v01.xlsx'));
await fs.writeFile(path.join(out,'qa_planilha_v01.json'),JSON.stringify({itens:170,precos_conferidos_individualmente:true,recalculo_de_mercado_verificado:true,conversoes_conferidas:true,faixas_e_revendas_conferidas:true,modelos_nao_alterados:true,orcamento:economy.getRange('B31:B42').values,normalizacoes:refs.getRange('C51:C54').values},null,2));
console.log('XLSX exportado: 170 itens, 3 abas.');
