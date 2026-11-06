"""Converte as cartas v04 e a metade de herói do Invocador para o jogo."""

import argparse
import hashlib
import json
import re
import unicodedata
from pathlib import Path


JOGO = Path(__file__).resolve().parents[1]
FONTES = JOGO / "tools/fontes_031"
SAIDA = JOGO / "data/cartas/invocador.json"
ENTIDADE = "Invocador"
PREFIXO = "classe.invocador."
ACOES = {
    "Padrão": "padrao",
    "Movimento": "movimento",
    "Reação": "reacao",
    "Padrão para chamar": "padrao",
    "Procedimento de Medicina ou ação indicada na poção": None,
    None: None,
}


def slug(nome):
    sem_acentos = unicodedata.normalize("NFKD", nome).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", sem_acentos.lower()).strip("-")


def custo(fadiga, acao, foco, texto):
    return {
        "fadiga": fadiga,
        "acao": ACOES[acao],
        "foco": foco,
        "outros": [f"{foco} Foco"] if foco else [],
        "permanente": "",
        "efeito": texto.partition(":")[2].strip() if ACOES[acao] else texto,
    }


def lado(fonte):
    face = {
        "nome": fonte["nome"],
        "texto": fonte["texto"],
        "tags": [],
        "limite_fadiga": fonte["limite_fadiga"],
        "natureza": fonte["natureza"],
        "acao_fonte": fonte["acao"],
        "custo": custo(fonte["custo_fadiga"], fonte["acao"], fonte["custo_foco"], fonte["texto"]),
    }
    for campo in ("criatura", "dificuldade_medicina", "dificuldade_medicina_referencia", "pocao_exigida"):
        if campo in fonte:
            face[campo] = fonte[campo]
    return face


def carta(fonte):
    lados = [lado(face) for face in fonte["lados"] if face is not None]
    meia = fonte["xp"] == 0.5
    if len(lados) != (1 if meia else 2):
        raise ValueError(f"Número de faces incompatível com XP em {fonte['id']}")
    if meia:
        lados.append(None)
    registro = {
        "id": PREFIXO + slug(lados[0]["nome"]),
        "id_fonte": fonte["id"],
        "fonte": "classe",
        "entidade": ENTIDADE,
        "grupo": fonte["grupo"],
        "tipo": fonte["tipo"],
        "xp": fonte["xp"],
        "meia_carta": meia,
        "lados": lados,
    }
    if fonte["tipo"] == "criatura":
        for campo in ("raridade", "virada_normal_permitida", "preparo_permitido", "modelo_recuperacao"):
            registro[campo] = fonte[campo]
    return registro


def heroi(fonte):
    ativada = fonte["ativada"]
    return {
        "id": PREFIXO + "heroi." + slug(fonte["nome"]),
        "fonte": "classe",
        "entidade": ENTIDADE,
        "nome": fonte["nome"],
        "descricao": "Invoca criaturas vinculadas e coordena seu movimento e seus ataques.",
        "passiva": fonte["passiva"]["texto"],
        "ativada": ativada["texto"],
        "desencadeada": fonte["desencadeada"]["texto"],
        "critico": fonte["critico"]["texto"],
        "custo_ativada": custo(ativada["custo_fadiga_editorial"], ativada["acao_editorial"], 0, ativada["texto"]),
        "limite_fadiga": fonte["limite_fadiga"],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fontes", type=Path, default=FONTES)
    parser.add_argument("--saida", type=Path, default=SAIDA)
    args = parser.parse_args()
    catalogo_bytes = (args.fontes / "habilidades_v04.json").read_bytes()
    conceito_bytes = (args.fontes / "conceito_v03.json").read_bytes()
    catalogo = json.loads(catalogo_bytes)
    conceito = json.loads(conceito_bytes)
    if catalogo["versao"] != 4 or conceito["versao"] != 3 or conceito["classe"] != ENTIDADE:
        raise ValueError("Use o catálogo v04 e o conceito v03 do Invocador.")
    cartas = [carta(c) for c in catalogo["cartas"]]
    for campo in ("id", "id_fonte"):
        if len({c[campo] for c in cartas}) != len(cartas):
            raise ValueError(f"Identificador duplicado no campo {campo}")
    saida = {
        "fonte": "classes/dados/invocador/habilidades_v04.json",
        "fonte_sha256": hashlib.sha256(catalogo_bytes).hexdigest(),
        "fonte_heroi": "classes/dados/invocador/conceito_v03.json",
        "fonte_heroi_sha256": hashlib.sha256(conceito_bytes).hexdigest(),
        "versao": catalogo["versao"],
        "estado": catalogo["estado"],
        "playtest_realizado": catalogo["playtest_realizado"],
        "herois": [heroi(conceito["redacao_editorial_do_heroi"])],
        "habilidades": cartas,
    }
    args.saida.write_text(json.dumps(saida, ensure_ascii=False, indent=1) + "\n",
                          encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
