## Provas do Círculo Rubro arquivadas pela guilda ao concluir os contratos.
extends RefCounted

const VAU := "fase:investigacao_vau_cinzento"
const PROVAS := {
	VAU: {"id": "livro_de_orsk", "titulo": "Livro do armazém de Orsk",
		"texto": "O livro liga o Círculo Rubro ao plano de esvaziar Vau-Cinzento para comprar suas terras. As remessas de beladona vieram do curtume de Ferrabrás."},
	"fase:bandidos_cao_vermelho": {"id": "carta_a_ferrabras", "titulo": "Carta a Ferrabrás",
		"texto": "A carta registra pagamentos do Círculo Rubro ao Cão Vermelho e reserva uma remessa ao Barão Corvin para a noite do baile."},
	"fase:baile_mascaras_prata": {"id": "carta_a_corvin", "titulo": "Carta ao Barão Corvin",
		"texto": "O Círculo Rubro prometeu devolver as terras de Corvin. A carta e o frasco de veneno ligam a promessa ao atentado contra a Duquesa no brinde."},
}
const DEDUCOES_VAU := {
	"vau_acesso_ao_veneno": "Acesso à beladona",
	"vau_rota_do_cais": "A rota do cais",
	"vau_pagamento": "O pagamento",
	"vau_meio_e_oportunidade": "Meio e oportunidade",
}


## Também recompõe o arquivo dos contratos vencidos em saves anteriores à v0.32.
static func atualizar(dados: Dictionary) -> void:
	if not dados.get("dossie") is Dictionary:
		dados["dossie"] = {}
	var entradas: Dictionary = dados["dossie"]
	for missao in PROVAS:
		if missao in dados.get("concluidas", []):
			var prova: Dictionary = PROVAS[missao]
			_arquivar(entradas, prova["id"], prova["titulo"], prova["texto"], missao)


static func registrar_vitoria(dados: Dictionary, batalha, missao: String) -> int:
	if not PROVAS.has(missao):
		return 0
	var entradas: Dictionary = dados["dossie"]
	var antes := entradas.size()
	atualizar(dados)
	if missao == VAU:
		var recibo := "Recibo do Círculo Rubro"
		if batalha.pistas.has(recibo):
			_arquivar(entradas, "recibo_de_orsk", recibo, batalha.pistas[recibo], missao)
		for id in DEDUCOES_VAU:
			if batalha.deducoes.has(id):
				_arquivar(entradas, id, "Dedução: " + DEDUCOES_VAU[id], batalha.deducoes[id], missao)
	return entradas.size() - antes


static func _arquivar(entradas: Dictionary, id: String, titulo: String, texto: String, missao: String) -> void:
	if not entradas.has(id):
		entradas[id] = {"titulo": titulo, "texto": texto, "missao": missao}
