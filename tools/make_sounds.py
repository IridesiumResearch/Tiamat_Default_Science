# SPDX-FileCopyrightText: Iridesium
# SPDX-License-Identifier: GPL-3.0-only
"""Generates the placeholder sounds for mods/tiamat_default_science/sounds.

One so far: `core_hum`, the Core turning (brief §6.8) — "a low choir that is
almost a hum". Four voices on a low A and its fifths and octave, each
breathing slowly in and out of step with the others, so the chord never
quite settles. Four seconds, and every partial and every breath completes a
whole number of cycles in that time, so the loop has no seam.

A WAV, mono, 16-bit, 22,050 Hz: the engine reads WAV and Ogg, and the
standard library writes WAV. No dependencies, no randomness: the same bytes
on every machine that has the same `math.sin`, and a sound is an asset, not
the simulation. Every sound here is meant to be replaced by a sound
designer's. Run from the repository root:

    python tools/make_sounds.py
"""
import math
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "mods" / "tiamat_default_science" / "sounds"

RATE = 22050
SECONDS = 4

# (frequency in Hz, loudness, breaths in the loop, phase of the breath)
VOICES = [
    (55.0, 0.40, 1, 0.00),     # A1, the ground of it
    (82.5, 0.22, 2, 0.25),     # E2, a fifth over
    (110.0, 0.18, 1, 0.50),    # A2, the octave
    (165.0, 0.10, 3, 0.75),    # E3, faint, and restless
    (220.25, 0.05, 2, 0.10),   # a quarter of a cycle sharp of A3 in four seconds: the beat that makes it wrong
]


def core_hum():
    n = RATE * SECONDS
    out = []
    for i in range(n):
        t = i / RATE
        s = 0.0
        for freq, loud, breaths, phase in VOICES:
            breath = 0.6 + 0.4 * math.sin(2 * math.pi * (breaths * t / SECONDS + phase))
            s += loud * breath * math.sin(2 * math.pi * freq * t)
        out.append(max(-1.0, min(1.0, s)))
    return out


SOUNDS = {"core_hum": core_hum}


def write(path, samples):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(round(s * 32000))) for s in samples))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        write(OUT / f"{name}.wav", make())
    print(f"wrote {len(SOUNDS)} sounds to {OUT}")


if __name__ == "__main__":
    main()
