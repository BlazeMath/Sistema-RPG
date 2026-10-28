"""Gera as músicas do jogo (0.16) por síntese, sem samples de terceiros.

Uso: python3 tools/gerar_musica.py   (precisa de numpy e ffmpeg com libvorbis)
Saída: assets/musica/{menu,exploracao,batalha,cripta}.ogg — loops sem emenda.
Clima: fantasia sombria (terra devastada). Tudo em ré menor / ré dórico.
"""
import os
import subprocess
import numpy as np

SR = 32000
SAIDA = os.path.join(os.path.dirname(__file__), "..", "assets", "musica")
rng = np.random.default_rng(21)


def nota(nome):
    """'D3' -> frequência."""
    tons = {"C": -9, "C#": -8, "Db": -8, "D": -7, "D#": -6, "Eb": -6, "E": -5, "F": -4, "F#": -3, "Gb": -3,
            "G": -2, "G#": -1, "Ab": -1, "A": 0, "A#": 1, "Bb": 1, "B": 2}
    letra, oit = nome[:-1], int(nome[-1])
    return 440.0 * 2 ** ((tons[letra] + 12 * (oit - 4)) / 12)


def env(n, a, d, s, r):
    """ADSR em amostras (a, d, r em segundos; s nível)."""
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    e = np.full(n, s, dtype=np.float64)
    a = min(a, n)
    e[:a] = np.linspace(0, 1, a, endpoint=False) if a > 0 else e[:a]
    if d > 0 and a + d < n:
        e[a:a + d] = np.linspace(1, s, d, endpoint=False)
    if r > 0 and r < n:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def osc(f, n, forma="seno", detune=0.0):
    t = np.arange(n) / SR
    fase = 2 * np.pi * f * (1 + detune) * t
    if forma == "seno":
        return np.sin(fase)
    if forma == "serra":
        x = (f * (1 + detune) * t) % 1.0
        return 2 * x - 1
    if forma == "triangulo":
        x = (f * (1 + detune) * t) % 1.0
        return 4 * np.abs(x - 0.5) - 1
    if forma == "quadrada":
        return np.sign(np.sin(fase))
    raise ValueError(forma)


def passa_baixa(x, corte):
    a = np.exp(-2 * np.pi * corte / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def passa_baixa_rapido(x, corte):
    # filtro de um polo vetorizado por blocos (aproximação suficiente para pads)
    from scipy.signal import lfilter
    a = np.exp(-2 * np.pi * corte / SR)
    return lfilter([1 - a], [1, -a], x)


class Faixa:
    def __init__(self, segundos):
        self.n = int(segundos * SR)
        self.e = np.zeros(self.n)
        self.d = np.zeros(self.n)

    def por(self, inicio, som, pan=0.0):
        i = int(inicio * SR) % self.n
        fim = i + len(som)
        ge, gd = np.sqrt(0.5 * (1 - pan)), np.sqrt(0.5 * (1 + pan))
        if fim <= self.n:
            self.e[i:fim] += som * ge
            self.d[i:fim] += som * gd
        else:  # dá a volta: o loop não tem emenda
            k = self.n - i
            self.e[i:] += som[:k] * ge
            self.d[i:] += som[:k] * gd
            self.e[:fim - self.n] += som[k:] * ge
            self.d[:fim - self.n] += som[k:] * gd

    def reverb(self, mistura=0.3):
        # ecos esparsos circulares (sala de pedra)
        out_e, out_d = self.e.copy(), self.d.copy()
        for atraso, ganho in [(0.031, 0.5), (0.047, 0.45), (0.071, 0.4), (0.113, 0.33), (0.167, 0.27), (0.239, 0.2), (0.353, 0.14), (0.5, 0.09)]:
            k = int(atraso * SR)
            out_e += mistura * ganho * np.roll(self.d, k)
            out_d += mistura * ganho * np.roll(self.e, k + 37)
        self.e, self.d = out_e, out_d

    def salvar(self, nome, volume=0.8):
        st = np.stack([self.e, self.d], axis=1)
        st /= max(np.max(np.abs(st)), 1e-9)
        st *= volume
        pcm = (st * 32767).astype(np.int16)
        os.makedirs(SAIDA, exist_ok=True)
        wav = os.path.join(SAIDA, nome + ".wav")
        import wave
        with wave.open(wav, "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        ogg = os.path.join(SAIDA, nome + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "3", ogg], check=True)
        os.remove(wav)
        print("ok", ogg)


# --- Instrumentos ------------------------------------------------------------------

def pad(f, dur, vol=0.12, brilho=900):
    n = int(dur * SR)
    s = sum(osc(f, n, "serra", d) for d in (-0.004, 0.0, 0.005)) / 3
    s += 0.5 * osc(f / 2, n, "seno")
    s = passa_baixa_rapido(s, brilho)
    return s * env(n, dur * 0.3, 0.2, 0.85, dur * 0.35) * vol


def harpa(f, dur=2.5, vol=0.22):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) + 0.12 * np.sin(6 * np.pi * f * t))
    return s * np.exp(-t * 2.6) * env(n, 0.004, 0, 1, 0.05) * vol


def sino(f, dur=5.0, vol=0.18):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for mult, g, dec in [(1, 1, 0.8), (2.76, 0.5, 1.4), (5.4, 0.25, 2.2), (8.93, 0.12, 3.0)]:
        s += g * np.sin(2 * np.pi * f * mult * t) * np.exp(-t * dec)
    return s * env(n, 0.002, 0, 1, 0.3) * vol


def flauta(f, dur, vol=0.12):
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.4, 0, 1)
    fase = 2 * np.pi * f * np.cumsum(vib) / SR
    s = np.sin(fase) + 0.2 * np.sin(2 * fase) + 0.04 * rng.standard_normal(n)
    s = passa_baixa_rapido(s, 2600)
    return s * env(n, 0.08, 0.1, 0.8, 0.25) * vol


def tambor(dur=0.9, vol=0.5, f=55):
    n = int(dur * SR)
    t = np.arange(n) / SR
    queda = f * (1 + 1.5 * np.exp(-t * 18))
    s = np.sin(2 * np.pi * np.cumsum(queda) / SR) * np.exp(-t * 5)
    s += 0.25 * passa_baixa_rapido(rng.standard_normal(n), 900) * np.exp(-t * 30)
    return s * vol


def corda_curta(f, dur=0.32, vol=0.1):
    n = int(dur * SR)
    s = sum(osc(f, n, "serra", d) for d in (-0.003, 0.003)) / 2
    s = passa_baixa_rapido(s, 1800)
    return s * env(n, 0.01, 0.08, 0.5, 0.12) * vol


def drone(f, dur, vol=0.12):
    n = int(dur * SR)
    t = np.arange(n) / SR
    mod = 1 + 0.3 * np.sin(2 * np.pi * t / dur * 2)   # respira duas vezes por loop
    s = osc(f, n, "serra", -0.002) + osc(f * 1.5, n, "serra", 0.003) * 0.5 + osc(f / 2, n, "seno")
    s = passa_baixa_rapido(s, 400)
    return s * mod * vol


# --- Peças ----------------------------------------------------------------------------

def menu():
    # 70 BPM, 8 compassos de 4 tempos = ~27,4 s; dois giros com melodia = ~55 s
    bpm = 70
    tempo = 60 / bpm
    compasso = 4 * tempo
    acordes = [["D3", "F3", "A3"], ["Bb2", "D3", "F3"], ["F2", "A2", "C3"], ["C3", "E3", "G3"],
               ["D3", "F3", "A3"], ["G2", "Bb2", "D3"], ["A2", "C#3", "E3"], ["A2", "C#3", "E3"]]
    f = Faixa(compasso * 16)
    for giro in range(2):
        for k, ac in enumerate(acordes):
            ini = (giro * 8 + k) * compasso
            for n_ in ac:
                f.por(ini, pad(nota(n_), compasso * 1.15), pan=-0.2)
            f.por(ini, pad(nota(ac[0]) / 2, compasso * 1.1, vol=0.08, brilho=300))
            # arpejo de harpa
            arp = [ac[0], ac[1], ac[2], ac[1]]
            for i in range(8):
                alt = nota(arp[i % 4]) * (2 if i >= 4 else 1) * 2
                f.por(ini + i * tempo / 2, harpa(alt, vol=0.14), pan=0.35)
    mel = [("A4", 2), ("F4", 1), ("G4", 1), ("A4", 3), ("D5", 1), ("C5", 2), ("Bb4", 1), ("A4", 1), ("G4", 4),
           ("F4", 2), ("E4", 1), ("F4", 1), ("D4", 4), ("E4", 2), ("F4", 1), ("G4", 1), ("A4", 4), ("C#5", 2), ("D5", 2)]
    t0 = 8 * compasso
    for nm, dur in mel:
        f.por(t0, flauta(nota(nm), dur * tempo * 1.05), pan=0.1)
        t0 += dur * tempo
    f.reverb(0.4)
    f.salvar("menu", 0.75)


def exploracao():
    # ré dórico, mais leve, 84 BPM
    bpm = 84
    tempo = 60 / bpm
    compasso = 4 * tempo
    acordes = [["D3", "A3", "E4"], ["C3", "G3", "D4"], ["D3", "A3", "F4"], ["G2", "D3", "B3"]]
    f = Faixa(compasso * 16)
    for k in range(16):
        ac = acordes[k % 4]
        ini = k * compasso
        for n_ in ac:
            f.por(ini, pad(nota(n_), compasso * 1.1, vol=0.08, brilho=1200), pan=0.15)
        for i in range(4):
            f.por(ini + i * tempo, harpa(nota(ac[i % 3]) * 2, vol=0.12), pan=-0.3)
    mel = [("D5", 1), ("E5", 1), ("F5", 2), ("E5", 1), ("D5", 1), ("C5", 2), ("D5", 3), ("A4", 1), ("B4", 2), ("C5", 2),
           ("D5", 4), ("F5", 1), ("G5", 1), ("A5", 2), ("G5", 1), ("F5", 1), ("E5", 2), ("D5", 4), ("C5", 2), ("B4", 2), ("A4", 4)]
    t0 = 4 * compasso
    for nm, dur in mel:
        f.por(t0, flauta(nota(nm), dur * tempo, vol=0.1))
        t0 += dur * tempo
    f.reverb(0.3)
    f.salvar("exploracao", 0.72)


def batalha():
    # 112 BPM, ostinato de cordas e tambores, ré menor
    bpm = 112
    tempo = 60 / bpm
    compasso = 4 * tempo
    baixos = ["D2", "D2", "Bb1", "Bb1", "G1", "G1", "A1", "A1"] * 2
    f = Faixa(compasso * 16)
    for k, b_ in enumerate(baixos):
        ini = k * compasso
        fb = nota(b_)
        for i in range(8):   # colcheias
            f.por(ini + i * tempo / 2, corda_curta(fb * 2 * (1.5 if i in (3, 7) else 1), vol=0.11), pan=-0.25)
        f.por(ini, pad(fb * 2, compasso, vol=0.06, brilho=600))
        for b in (0, 1.5, 2, 3):
            f.por(ini + b * tempo, tambor(vol=0.45 if b == 0 else 0.3, f=50 if b == 0 else 62), pan=0.1)
        if k % 2 == 1:
            f.por(ini + 3.5 * tempo, tambor(0.4, 0.25, 80), pan=0.3)
    mel = [("D5", 1.5), ("C5", 0.5), ("D5", 1), ("F5", 1), ("E5", 2), ("D5", 2), ("Bb4", 1.5), ("A4", 0.5), ("Bb4", 1), ("D5", 1),
           ("C5", 4), ("G4", 1), ("A4", 1), ("Bb4", 1), ("D5", 1), ("C#5", 2), ("E5", 2), ("D5", 4)]
    t0 = 8 * compasso
    for nm, dur in mel:
        f.por(t0, pad(nota(nm), dur * tempo, vol=0.09, brilho=2200), pan=0.2)
        t0 += dur * tempo
    f.reverb(0.22)
    f.salvar("batalha", 0.8)


def cripta():
    # ambiente: drone grave, sinos dissonantes, sopro
    dur = 64.0
    f = Faixa(dur)
    f.por(0, drone(nota("D2"), dur, vol=0.12))
    f.por(0, drone(nota("Eb2") * 1.002, dur, vol=0.04), pan=0.4)
    for i, (t, nm) in enumerate([(2, "D5"), (9, "A4"), (15, "Eb5"), (23, "D5"), (30, "F4"), (38, "Ab4"), (45, "D5"), (53, "C5"), (59, "A4")]):
        f.por(t, sino(nota(nm), vol=0.12), pan=(-0.5 if i % 2 else 0.5))
    vento = passa_baixa_rapido(rng.standard_normal(f.n), 500)
    vento *= 0.04 * (1 + np.sin(2 * np.pi * np.arange(f.n) / f.n * 3)) / 2
    f.e += vento
    f.d += np.roll(vento, 4000)
    f.reverb(0.5)
    f.salvar("cripta", 0.7)


if __name__ == "__main__":
    menu()
    exploracao()
    batalha()
    cripta()
