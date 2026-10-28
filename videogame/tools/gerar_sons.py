"""Gera os efeitos sonoros do jogo (0.21) por síntese, sem samples de terceiros.

Uso: python3 tools/gerar_sons.py   (precisa de numpy)
Saída: assets/sons/{passos,golpe,tiro,magia,acerto,cura}.wav (mono, 22050 Hz, 16 bits).
"""
import os
import wave
import numpy as np

SR = 22050
SAIDA = os.path.join(os.path.dirname(__file__), "..", "assets", "sons")
rng = np.random.default_rng(7)


def t(seg):
    return np.arange(int(seg * SR)) / SR


def ruido(seg):
    return rng.uniform(-1, 1, int(seg * SR))


def passa_baixa(x, a):
    y = np.zeros_like(x)
    for i in range(1, len(x)):
        y[i] = y[i - 1] + a * (x[i] - y[i - 1])
    return y


def env(n, ataque, queda):
    tt = np.arange(n) / SR
    e = np.minimum(tt / max(ataque, 1e-4), 1.0) * np.exp(-tt / queda)
    return e


def salvar(nome, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.8
    dados = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(SAIDA, nome + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(dados.tobytes())


def passos():
    um = passa_baixa(ruido(0.09), 0.08) * env(int(0.09 * SR), 0.003, 0.025)
    um += 0.6 * np.sin(2 * np.pi * 70 * t(0.09)) * env(int(0.09 * SR), 0.002, 0.03)
    pausa = np.zeros(int(0.17 * SR))
    return np.concatenate([um, pausa, um * 0.8, np.zeros(int(0.05 * SR))])


def golpe():
    n = int(0.32 * SR)
    sopro = passa_baixa(ruido(0.32), 0.25) * np.sin(np.linspace(0, np.pi, n)) ** 2 * 0.5
    baque = np.zeros(n)
    k = int(0.16 * SR)
    m = n - k
    baque[k:] = (np.sin(2 * np.pi * 95 * t(m / SR)) + 0.5 * passa_baixa(ruido(m / SR), 0.2)) * env(m, 0.002, 0.05)
    return sopro + baque


def tiro():
    n = int(0.35 * SR)
    f = 180 * np.exp(-t(0.35) * 9) + 90
    corda = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.001, 0.08)
    assobio = passa_baixa(ruido(0.35), 0.5) * env(n, 0.02, 0.12) * 0.3
    return corda + assobio


def magia():
    n = int(0.7 * SR)
    x = np.zeros(n)
    for k, fr in enumerate([660, 880, 1320, 1760]):
        x += np.sin(2 * np.pi * fr * t(0.7) + k) * env(n, 0.03 + 0.02 * k, 0.25) / (k + 1)
    x += passa_baixa(ruido(0.7), 0.6) * env(n, 0.05, 0.2) * 0.2
    return x


def acerto():
    n = int(0.22 * SR)
    return (np.sin(2 * np.pi * 120 * t(0.22)) * 0.8 + passa_baixa(ruido(0.22), 0.35)) * env(n, 0.001, 0.045)


def cura():
    n = int(1.0 * SR)
    x = np.zeros(n)
    for k, fr in enumerate([523.25, 659.25, 783.99, 1046.5]):
        atraso = int(k * 0.09 * SR)
        m = n - atraso
        x[atraso:] += np.sin(2 * np.pi * fr * t(m / SR)) * env(m, 0.01, 0.35)
    return x


if __name__ == "__main__":
    os.makedirs(SAIDA, exist_ok=True)
    for nome, f in [("passos", passos), ("golpe", golpe), ("tiro", tiro), ("magia", magia), ("acerto", acerto), ("cura", cura)]:
        salvar(nome, f())
    print("ok")
