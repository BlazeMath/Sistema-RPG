"""Aplica em data/cartas/habilidades.json a revisão de 27/10/2026 das cartas de habilidade
("Habilidades_Cartas_1.pdf": 17 faces revisadas; o resto da coleção não mudou).

A planilha oficial ainda não foi reexportada com a revisão: este script corrige os textos
das faces revisadas (e o limite da Flecha de Rede) até a próxima exportação.
Uso: python3 tools/aplicar_revisao_cartas.py
"""
import json

REVISAO = {
    "Ombro de Ferro": "Ação Padrão: mova-se 1 quadrado e faça um ataque corpo a corpo. Se causar dano, o alvo recebe 1 ficha de Imobilizar.",
    "Avalanche": "Ação Padrão: faça um ataque corpo a corpo. Some o dobro da resistência da sua armadura ao dano. Você recebe 1 ficha de Imobilizar.",
    "Ombro de Aço": "O limite dos testes de defesa dos seus aliados adjacentes tem +1.",
    "Hino de Coragem": "Ação Padrão: até o início do seu próximo turno, aliados ao alcance 2 não podem ter fichas de Medo e Confusão colocadas por efeitos de inimigos.",
    "Ressurgir": "Ação Padrão: exile metade das cartas do descarte do aliado alvo, arredondando para cima. Se o alvo estiver sem cartas no baralho, ele cura um valor igual à sua Sabedoria e recobra a consciência no local onde seu corpo está.",
    "Preparar o Tiro": "Ação Padrão: ganhe 2 fichas de Mira. Se você não se moveu neste turno, ganhe 3 em vez de 2. Depois de usar esta habilidade, você não pode se mover até o fim do turno.",
    "Flecha de Rede": "Ação Padrão: faça um ataque à distância causando metade do dano. Se acertar, o alvo recebe 2 fichas de Imobilizar e não pode usar reações até o próximo turno dele.",
    "Flecha Pesada": "Durante seu ataque, se o defensor tiver ao menos 1 ficha de Ferimento ou de Imobilizar, o dano da sua arma é triplicado e ignora resistência.",
    "Predador Absoluto": "No início da cena com este lado revelado, ou ao revelá-lo pela primeira vez na cena, escolha um inimigo visível como alvo da caça. Até o fim da cena, coloque o dobro das fichas que seus efeitos colocariam no alvo. Nos efeitos sobre ele calculados pela quantidade de fichas gastas, calcule como se gastasse o dobro, pagando o custo normal. Duplique cada efeito apenas uma vez por esta habilidade. No fim do seu turno, se causou dano ao alvo neste turno, ganhe 1 ficha de Preparo. Quando ele morrer, escolha outro inimigo visível.",
    "Conjuração Perfeita": "Uma vez por turno, você pode conjurar uma magia pagando apenas 1 de Fadiga. Os outros custos da magia continuam valendo.",
    "Mana Densa": "Descarte 1 carta: quando uma magia tiver você como um dos alvos, faça um teste contestado do seu Raciocínio contra a Sabedoria do conjurador. Se vencer, anule a magia.",
    "Adaga Fantasma": "Como parte de seu ataque, você pode colocar 1 ficha de Atormentado nesta carta. Se fizer isso, ao acertar esse ataque, o defensor recebe 1 ficha de Ferimento.",
    "Torcer a Lâmina": "Seu próximo ataque corpo a corpo neste turno aplica 1 ficha de Sangramento no defensor se acertar.",
    "Bote Fatal": "Sempre que você acertar um ataque corpo a corpo, o defensor recebe 1 ficha de Ferimento para cada ficha de Sombra que você tem.",
    "Roubo Arcano": "Descarte 1 ficha de Reação: quando um inimigo conjurar uma magia, faça um teste do seu Raciocínio contra a Sabedoria do conjurador. Em caso de sucesso, escolha novos alvos válidos para a magia, respeitando sua quantidade de alvos, seu alcance e suas restrições; resolva a magia contra esses alvos e, depois, coloque 1 ficha de Atordoamento nesta carta.",
    "Teologia": "Aumente seu limite em +1 para testes de Religião. 1 de fadiga, Ação Padrão: desenhe o símbolo de sua divindade em uma arma ou armadura. Até o próximo amanhecer, ela não pode ser amaldiçoada nem ser quebrada diretamente por efeitos de inimigos. Se a vida do item chegar a 0, ele quebra normalmente. Limitado a um item por vez.",
    "Olho que Tudo Vê": "No início do seu turno, ganhe 1 ficha de Mira. Você pode acumular Mira sem limite.",
    "Nunca Visto": "No início do seu turno, ganhe 1 ficha de Sombra.",
    "Estratégia Arcana": "No início do seu turno, compre uma carta.",
    "De Volta ao Básico": "Você faz testes mentais (Raciocínio, Percepção, Sabedoria) com vantagem.",
    "Lâmina na Manga": "Você causa +1 de dano para cada ficha de Sombra que possui.",
}
LIMITES = {"Flecha de Rede": 2}
TAGS_NOVAS = {"Condenar": ["Marcação"]}


def main():
    p = 'data/cartas/habilidades.json'
    cartas = json.load(open(p, encoding='utf-8'))
    feitas = []
    for c in cartas:
        for l in c['lados']:
            if not l:
                continue
            n = l['nome']
            if n in REVISAO:
                txt = REVISAO[n]
                fad = int((l.get('custo') or {}).get('fadiga') or 0)
                if fad > 0 and not txt.startswith('%d de fadiga' % fad) and n != 'Teologia':
                    txt = '%d de fadiga, %s' % (fad, txt) if txt.startswith('Ação') else txt
                l['texto'] = txt
                if isinstance(l.get('custo'), dict):
                    l['custo']['efeito'] = REVISAO[n].split(':', 1)[1].strip() if ':' in REVISAO[n][:40] else REVISAO[n]
                feitas.append(n)
            if n in LIMITES:
                l['limite_fadiga'] = LIMITES[n]
            for t in TAGS_NOVAS.get(n, []):
                if t not in l['tags']:
                    l['tags'].append(t)
    json.dump(cartas, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(len(feitas), 'faces revisadas:', ', '.join(feitas))


if __name__ == '__main__':
    main()
