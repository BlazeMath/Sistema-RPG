"""Converte o catálogo de teste v02 do Investigador para o formato do jogo."""

import argparse
import hashlib
import json
import re
import unicodedata
from pathlib import Path


JOGO = Path(__file__).resolve().parents[1]
FONTE = JOGO / "tools/fontes_030/investigador_catalogo_v02.json"
SAIDA = JOGO / "data/cartas/investigador.json"
ENTIDADE = "Investigador"
PREFIXO = "classe.investigador."
ACOES = {"Padrão": "padrao", "Movimento": "movimento", "Reação": "reacao",
         "Junto ao teste": None, None: None}


def slug(nome):
    ascii_nome = unicodedata.normalize("NFKD", nome).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", ascii_nome.lower()).strip("-")


def custo(fadiga, acao, outros, texto):
    pistas = re.match(r"^(\d+) Pistas?\b", outros or "")
    return {
        "fadiga": fadiga,
        "acao": ACOES[acao],
        "outros": [outros] if outros else [],
        "pistas": int(pistas[1]) if pistas else 0,
        "permanente": "",
        "efeito": texto.partition(":")[2].strip() if acao is not None else texto,
    }


def lado(fonte):
    return {
        "nome": fonte["nome"],
        "texto": fonte["texto"],
        "tags": [],
        "limite_fadiga": fonte["limite_fadiga"],
        "natureza": fonte["natureza"],
        "acao_fonte": fonte["acao"],
        "custo": custo(fonte["custo_fadiga"], fonte["acao"], fonte["outros_custos"], fonte["texto"]),
    }


def habilidade(fonte):
    lados = [lado(face) for face in fonte["lados"] if face is not None]
    meia = fonte["xp"] == 0.5
    if len(lados) != (1 if meia else 2):
        raise ValueError(f"Número de faces incompatível com XP em {fonte['id']}")
    if meia:
        lados.append(None)
    return {
        "id": PREFIXO + slug(lados[0]["nome"]),
        "id_fonte": fonte["id"],
        "fonte": "classe",
        "entidade": ENTIDADE,
        "grupo": fonte["grupo"],
        "xp": fonte["xp"],
        "meia_carta": meia,
        "lados": lados,
    }


def heroi(fonte):
    ativada = fonte["ativada"]
    texto = ativada["texto"]
    pistas = re.search(r"\b\d+ Pistas?\b", texto.partition(":")[0])
    return {
        "id": PREFIXO + "heroi." + slug(fonte["nome"]),
        "id_fonte": fonte["id"],
        "fonte": "classe",
        "entidade": ENTIDADE,
        "nome": fonte["nome"],
        "descricao": fonte["identidade"],
        "passiva": fonte["passiva"]["texto"],
        "ativada": texto,
        "desencadeada": fonte["desencadeada"]["texto"],
        "critico": fonte["critico"]["texto"],
        "custo_ativada": custo(ativada["custo_fadiga"], ativada["acao"], pistas[0] if pistas else None, texto),
        "limite_fadiga": fonte["limite_fadiga"],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fonte", type=Path, default=FONTE)
    parser.add_argument("--saida", type=Path, default=SAIDA)
    args = parser.parse_args()
    original = args.fonte.read_bytes()
    catalogo = json.loads(original)
    if catalogo["versao"] != 2:
        raise ValueError("Use o catálogo v02 do Investigador.")
    herois = [heroi(h) for h in catalogo["herois"]]
    habilidades = [habilidade(c) for c in catalogo["cartas"]]
    for campo in ("id", "id_fonte"):
        ids = [c[campo] for c in herois + habilidades]
        if len(set(ids)) != len(ids):
            raise ValueError(f"Identificador duplicado no campo {campo}")
    saida = {
        "fonte": "classes/dados/investigador/catalogo_proposto_v02.json",
        "fonte_sha256": hashlib.sha256(original).hexdigest(),
        "versao": catalogo["versao"],
        "estado": catalogo["estado"],
        "playtest_realizado": catalogo["playtest_realizado"],
        "herois": herois,
        "habilidades": habilidades,
    }
    args.saida.write_text(json.dumps(saida, ensure_ascii=False, indent=1) + "\n",
                          encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
