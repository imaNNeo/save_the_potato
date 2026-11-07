"""Level songs built on famous public-domain melodies.

These are our own arrangements of the tunes (the notes only, written down
here by hand) played by the game's own synth. No recording is used.
Every composer here died more than 100 years ago, so the melodies are in
the public domain.

Each tune is fitted to the game's grid: 8 bars of 4 beats, a note on
every downbeat, and exactly 17 notes on a beat and 6 between beats. That
keeps the rhythm director and its density rules unchanged, so some notes
are merged, dotted or added compared with the sheet music.

A song gives one or two 8 bar themes (A, and B over the same chords).
The five phrases the game rotates through are made from them:
  home = A, valley = B, lift = A with its second half an octave up,
  tense = B an octave up, peak = A an octave up.
"""
import synth

MAJOR = [0, 2, 4, 5, 7, 9, 11]
MINOR = [0, 2, 3, 5, 7, 8, 10]


def parse(bars):
    """['0:F#5 1:G5', ...] -> [(bar, beat, midi), ...]"""
    notes = []
    for i, bar in enumerate(bars):
        for tok in bar.split():
            beat, name = tok.split(':')
            beat = float(beat)
            notes.append((i, int(beat) if beat == int(beat) else beat, synth.n(name)))
    return notes


def counts(notes):
    down = sum(1 for _, b, _ in notes if b == 0)
    on = sum(1 for _, b, _ in notes if b != 0 and b == int(b))
    off = sum(1 for _, b, _ in notes if b != int(b))
    return down, on, off


def shift(notes, semis, from_bar=0):
    return [(b, beat, m + (semis if b >= from_bar else 0)) for b, beat, m in notes]


def phrase(name, notes, bias=0):
    mids = sorted(m for _, _, m in notes)
    return dict(name=name, iceFrom=int(mids[len(mids) // 2] + bias), notes=notes)


def build(song):
    a = parse(song['A'])
    b = parse(song.get('B', song['A']))
    for label, t in (('A', a), ('B', b)):
        bars = {bar for bar, beat, _ in t if beat == 0}
        assert counts(t) == (8, 17, 6) and bars == set(range(8)), (song['name'], label, counts(t))
    bias = song.get('ice_bias', 0)
    return {
        'home': phrase('home', a, bias),
        'valley': phrase('valley', b, bias),
        'lift': phrase('lift', shift(a, 12, 4), bias),
        'tense': phrase('tense', shift(b, 12), bias),
        'peak': phrase('peak', shift(a, 12), bias),
    }


M, m = 'M', 'm'

CLASSICAL = [
    dict(
        level=1, name='Prelude', tonic='C', mode=MAJOR, bpm=96,
        composer='J. S. Bach', piece='Prelude in C major, BWV 846 (1722)',
        # C  Dm/C  G7/B  C  Am/C  D7/C  G/B  Cmaj7/B
        chords=[(0, M), (2, m), (7, M), (0, M), (9, m), (2, M), (7, M), (0, M)],
        groove='soft',
        mood='Bach\'s rolling arpeggios. The shield plays the top of each broken chord, calm and even.',
        colors=['#a8e6cf', '#3d7a63', '#08170f'],
        A=[
            '0:G4 1:C5 2:E5 2.5:C5 3:E5',
            '0:A4 1:D5 2:F5 2.5:D5 3:F5',
            '0:G4 1:D5 2:F5',
            '0:G4 1:C5 2:E5 2.5:C5 3:E5',
            '0:A4 1:E5 2:A5 2.5:E5 3:A5',
            '0:F#4 1:A4 2:D5',
            '0:G4 1.5:D5 2:G5 3.5:D5',
            '0:C5',
        ],
        B=[
            '0:E5 1:C5 2:G4 2.5:C5 3:G4',
            '0:F5 1:D5 2:A4 2.5:D5 3:A4',
            '0:F5 1:D5 2:G4',
            '0:E5 1:C5 2:G4 2.5:C5 3:G4',
            '0:A5 1:E5 2:A4 2.5:E5 3:A4',
            '0:D5 1:A4 2:F#4',
            '0:G5 1.5:D5 2:G4 3.5:D5',
            '0:E4',
        ],
    ),
    dict(
        level=2, name='Joy', tonic='D', mode=MAJOR, bpm=104,
        composer='L. van Beethoven', piece='Ode to Joy, Symphony No. 9 (1824)',
        chords=[(0, M), (7, M), (0, M), (7, M), (0, M), (7, M), (0, M), (7, M)],
        groove='pop',
        mood='Ode to Joy with a little bounce: a few notes are dotted so it swings.',
        colors=['#ffe9a8', '#8a6d1f', '#1a1404'],
        A=[
            '0:F#5 1:F#5 2:G5 3:A5',
            '0:A5 1:G5 2:F#5 3:E5',
            '0:D5 1:D5 2:E5 3:F#5',
            '0:F#5 1.5:E5 2:E5',
            '0:F#5 1.5:F#5 2:G5 3:A5',
            '0:A5 1.5:G5 2:F#5 3:E5',
            '0:D5 1.5:D5 2:E5 3:F#5',
            '0:E5 1.5:D5 2:D5 3.5:E5',
        ],
        B=[
            '0:E5 1:E5 2:F#5 3:D5',
            '0:E5 1:F#5 1.5:G5 2:F#5 3:D5',
            '0:E5 1:F#5 1.5:G5 2:F#5',
            '0:D5 1:E5 2:A4',
            '0:F#5 1.5:F#5 2:G5 3:A5',
            '0:A5 1.5:G5 2:F#5 3:E5',
            '0:D5 1.5:D5 2:E5 3:F#5',
            '0:E5 1.5:D5 2:D5',
        ],
    ),
    dict(
        level=3, name='Elise', tonic='A', mode=MINOR, bpm=108,
        composer='L. van Beethoven', piece='Für Elise, WoO 59 (1810)',
        chords=[(0, m), (7, M), (0, m), (7, M), (0, m), (7, M), (0, m), (7, M)],
        groove='halftime',
        mood='Für Elise: the high E-D# turn is ice, the low broken chords are fire.',
        colors=['#d6c2ff', '#5a3f8f', '#0f0920'],
        A=[
            '0:E5 1:D#5 2:E5 3:D#5',
            '0:E5 1:B4 2:D5 3:C5',
            '0:A4 1.5:C4 2:E4 3:A4',
            '0:B4 1.5:E4 2:G#4 3:B4',
            '0:C5 1.5:E4 2:E5 3:D#5',
            '0:E5 0.5:D#5 1:E5 1.5:B4 2:D5 3:C5',
            '0:A4 1.5:E4 2:C5 3:B4',
            '0:A4',
        ],
    ),
    dict(
        level=4, name='Canon', tonic='D', mode=MAJOR, bpm=112,
        composer='J. Pachelbel', piece='Canon in D (about 1690)',
        # D  A  Bm  F#m  G  D  G  A
        chords=[(0, M), (7, M), (9, m), (4, m), (5, M), (0, M), (5, M), (7, M)],
        groove='syncop',
        mood='Pachelbel\'s eight chords. The downbeats walk the famous line down: F# E D C# B A B C#.',
        colors=['#ffc8dd', '#8f3f63', '#1c0812'],
        A=[
            '0:F#5 2:A5 3:F#5',
            '0:E5 1:C#5 2:E5 3:A5',
            '0:D5 2:F#5 2.5:E5 3:D5',
            '0:C#5 2:A4 3:C#5',
            '0:B4 1:D5 2:G5 3:F#5',
            '0:A4 1.5:D5 2:F#5 3:A5',
            '0:B4 1.5:D5 2:G5 3:F#5',
            '0:C#5 1.5:E5 2:A5 2.5:G5 3.5:E5',
        ],
        B=[
            '0:D5 1:F#5 2:A5 3:G5',
            '0:F#5 1:D5 2:F#5 3:E5',
            '0:D5 1:B4 2:D5 3:A4',
            '0:A4 1:C#5 2:F#5 2.5:E5',
            '0:B4 1:D5 2:G5 2.5:F#5',
            '0:F#5 1.5:A5 2:F#5 2.5:D5',
            '0:G5 1:D5 1.5:B4 3:D5',
            '0:C#5 1.5:E5 3:A4',
        ],
    ),
    dict(
        level=5, name='Swan', tonic='B', mode=MINOR, bpm=116,
        composer='P. I. Tchaikovsky', piece='Swan Lake, Op. 20 (1876)',
        chords=[(0, m), (0, m), (8, M), (0, m), (8, M), (0, m), (5, m), (7, M)],
        groove='epic',
        mood='The Swan Lake theme. Long high notes with soft echoes below, then it falls and turns.',
        colors=['#c9e4ff', '#34557a', '#060d18'],
        ice_bias=-1,
        A=[
            '0:B4 1:C#5 2:D5 3:E5',
            '0:F#5 2:B4 3:D5',
            '0:F#5 2:B4 3:D5',
            '0:F#5 2:D5 3:B4',
            '0:D5 1:B4 2:G4 3:D5',
            '0:B4 1.5:F#4 2:B4 2.5:D5 3:F#5',
            '0:G5 1:F#5 1.5:E5 2:D5 3:E5',
            '0:F#5 1.5:C#5 2.5:A#4 3.5:F#4',
        ],
    ),
    dict(
        level=6, name='Mountain King', tonic='B', mode=MINOR, bpm=120,
        composer='E. Grieg', piece='In the Hall of the Mountain King, Peer Gynt (1875)',
        # Bm  Bm  C#  C  Bm  Bm  D  D
        chords=[(0, m), (0, m), (2, M), (1, M), (0, m), (0, m), (3, M), (3, M)],
        groove='drive',
        mood='The sneaking troll march, fast. It ends on syncopated stabs that fall into the next round.',
        colors=['#ff8a5c', '#7a2a12', '#170603'],
        ice_bias=1,
        A=[
            '0:B4 1:C#5 2:D5 3:E5',
            '0:F#5 1:D5 2:F#5',
            '0:F5 1:C#5 2:F5',
            '0:E5 1:C5 2:E5',
            '0:B4 1:C#5 2:D5 3:E5',
            '0:F#5 1:D5 2:F#5 2.5:A5 3:B5',
            '0:A5 0.5:F#5 1:D5 1.5:F#5 2:A5',
            '0:A5 1.5:F#5 2.5:D5 3.5:A4',
        ],
    ),
]

BY_LEVEL = {s['level']: s for s in CLASSICAL}

if __name__ == '__main__':
    for s in CLASSICAL:
        ps = build(s)
        print(s['level'], s['name'], {k: (min(m for *_, m in p['notes']), max(m for *_, m in p['notes']), p['iceFrom']) for k, p in ps.items()})
