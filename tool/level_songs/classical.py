"""Level songs built on famous public-domain tunes, written out note for note.

Every tune here comes from a public-domain edition of the sheet music
(the Mutopia Project, mutopiaproject.org, except Ode to Joy, which is
written from the score by hand). The game's own synth plays them; no
recording is used, and every composer died more than 100 years ago.

A tune is one long phrase: every note of the melody, on the beat where
the score has it, in the order the piece plays them. The game plays all
of them as orbs (Song.fullMelody), so a player who knows the tune can play
it by heart. Only grace notes and trills are left out, and a few chords
are reduced to their top note.

Bars are written 'beat:Note ...'. The beat unit is the one the song's
bpm counts: a quarter note, or an eighth for Für Elise and the Rondo
alla Turca. A chord entry is (semitones above the tonic, 'M' or 'm') for
the bar, or a list of them that share the bar evenly.
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


def build(song):
    notes = parse(song['bars'])
    n = len(song['bars'])
    assert len(song['chords']) == n, (song['name'], len(song['chords']), n)
    for bar, beat, _ in notes:
        assert 0 <= beat < song['beats'], (song['name'], bar, beat)
    mids = sorted(m for _, _, m in notes)
    ice_from = int(mids[len(mids) // 2] + song.get('ice_bias', 0))
    kinds = phrase_kinds(song, notes)
    notes = [(b, t, x, k) for (b, t, x), k in zip(notes, kinds)]
    return {'tune': dict(name='tune', iceFrom=ice_from, notes=notes)}


def phrase_groups(song, notes):
    """Splits the tune where it breathes: a gap of song['breath'] beats
    (2 by default) or more between two notes ends a group (a motif or a
    phrase)"""
    breath = song.get('breath', 2)
    groups, cur, prev = [], [], None
    for i, (b, t, _) in enumerate(notes):
        at = b * song['beats'] + t
        if prev is not None and at - prev >= breath:
            groups.append(cur)
            cur = []
        cur.append(i)
        prev = at
    groups.append(cur)
    if len(groups) > 1 and notes[0][:2] == (0, 0) and len(notes) > 1:
        # the tune loops: a group running into the end joins the start
        last_at = notes[-1][0] * song['beats'] + notes[-1][1]
        total = len(song['bars']) * song['beats']
        if total - last_at < breath:
            groups[0] = groups.pop() + groups[0]
    return groups


def ending(song):
    """(pickup_from, ends_at): the beat of the last bar where the pickup
    into the next round starts (None if there is none), and the beat of
    the last bar the level ends on. The last round leaves the pickup out
    and ends on the tune's last note, or on the next downbeat (with the
    tonic chord) when that note is not a tonic chord tone."""
    notes = parse(song['bars'])
    groups = phrase_groups(song, notes)
    last = len(song['bars']) - 1
    joined = [i for i in groups[0] if notes[i][0] == last]
    pickup_from = min(notes[i][1] for i in joined) if joined else None
    ending_notes = [n for n in notes if n[0] == last and (pickup_from is None or n[1] < pickup_from)]
    final = ending_notes[-1]
    tonic = synth.NOTE[song['tonic']]
    triad = {tonic, (tonic + (4 if song['mode'] == MAJOR else 3)) % 12, (tonic + 7) % 12}
    ends_at = final[1] if final[2] % 12 in triad else song['beats']
    return pickup_from, ends_at


def phrase_kinds(song, notes):
    """Fire or ice for each note, one kind for a whole group, so a motif
    and the note that ends it are played on the same side. Higher groups
    are ice, lower ones fire (split at the middle group)."""
    groups = phrase_groups(song, notes)
    means = [sum(notes[i][2] for i in g) / len(g) for g in groups]
    split = sorted(means)[len(means) // 2] + song.get('group_bias', 0)
    kinds = [None] * len(notes)
    for k, (g, mean) in enumerate(zip(groups, means)):
        # call and response: phrases that sit at the same height take turns
        ice = k % 2 == 0 if song.get('call_response') else mean >= split
        for i in g:
            kinds[i] = ice
    return kinds


def bar_chords(song, bar):
    """The chords of a bar as [(start beat, chord), ...]"""
    c = song['chords'][bar]
    cs = c if isinstance(c, list) else [c]
    step = song['beats'] / len(cs)
    return [(i * step, ch) for i, ch in enumerate(cs)]


def max_rate(song):
    """The most notes a second anywhere in the tune, over any one beat"""
    beat_s = 60 / song['bpm']
    times = [(b * song['beats'] + t) * beat_s for b, t, _ in parse(song['bars'])]
    return max(sum(1 for u in times if x <= u < x + beat_s - 1e-6) for x in times) / beat_s


M, m = 'M', 'm'

CLASSICAL = [
    dict(
        level=1, name='Joy', tonic='D', mode=MAJOR, bpm=100, beats=4,
        composer='L. van Beethoven', piece='Ode to Joy, Symphony No. 9 (1824)',
        groove='pop',
        call_response=True,
        mood='Ode to Joy, all 16 bars as Beethoven wrote them, in D.',
        colors=['#ffe9a8', '#8a6d1f', '#1a1404'],
        bars=[
            '0:F#5 1:F#5 2:G5 3:A5',
            '0:A5 1:G5 2:F#5 3:E5',
            '0:D5 1:D5 2:E5 3:F#5',
            '0:F#5 1.5:E5 2:E5',
            '0:F#5 1:F#5 2:G5 3:A5',
            '0:A5 1:G5 2:F#5 3:E5',
            '0:D5 1:D5 2:E5 3:F#5',
            '0:E5 1.5:D5 2:D5',
            '0:E5 1:E5 2:F#5 3:D5',
            '0:E5 1:F#5 1.5:G5 2:F#5 3:D5',
            '0:E5 1:F#5 1.5:G5 2:F#5 3:E5',
            '0:D5 1:E5 2:A4',
            '0:F#5 1:F#5 2:G5 3:A5',
            '0:A5 1:G5 2:F#5 3:E5',
            '0:D5 1:D5 2:E5 3:F#5',
            '0:E5 1.5:D5 2:D5',
        ],
        chords=[(0, M), [(0, M), (7, M)], (0, M), [(0, M), (7, M)],
                (0, M), [(0, M), (7, M)], (0, M), [(7, M), (0, M)],
                [(7, M), (0, M)], [(7, M), (0, M)], [(7, M), (11, m)], [(2, M), (7, M)],
                (0, M), [(0, M), (7, M)], (0, M), [(7, M), (0, M)]],
    ),
    dict(
        level=2, name='Minuet', tonic='G', mode=MAJOR, bpm=104, beats=3,
        composer='C. Petzold (once credited to J. S. Bach)', piece='Minuet in G, from the Notebook for Anna Magdalena Bach (1725)',
        source='Mutopia Project, anna-magdalena-04',
        ice_bias=1,
        groove='waltz',
        call_response=True,
        mood='The Minuet in G, both halves, in 3/4. Its second half turns to D major and walks home.',
        colors=['#a8e6cf', '#3d7a63', '#08170f'],
        bars=[
            '0:D5 1:G4 1.5:A4 2:B4 2.5:C5',
            '0:D5 1:G4 2:G4',
            '0:E5 1:C5 1.5:D5 2:E5 2.5:F#5',
            '0:G5 1:G4 2:G4',
            '0:C5 1:D5 1.5:C5 2:B4 2.5:A4',
            '0:B4 1:C5 1.5:B4 2:A4 2.5:G4',
            '0:F#4 1:G4 1.5:A4 2:B4 2.5:G4',
            '0:A4',
            '0:D5 1:G4 1.5:A4 2:B4 2.5:C5',
            '0:D5 1:G4 2:G4',
            '0:E5 1:C5 1.5:D5 2:E5 2.5:F#5',
            '0:G5 1:G4 2:G4',
            '0:C5 1:D5 1.5:C5 2:B4 2.5:A4',
            '0:B4 1:C5 1.5:B4 2:A4 2.5:G4',
            '0:A4 1:B4 1.5:A4 2:G4 2.5:F#4',
            '0:G4',
            '0:B5 1:G5 1.5:A5 2:B5 2.5:G5',
            '0:A5 1:D5 1.5:E5 2:F#5 2.5:D5',
            '0:G5 1:E5 1.5:F#5 2:G5 2.5:D5',
            '0:C#5 1:B4 1.5:C#5 2:A4',
            '0:A4 0.5:B4 1:C#5 1.5:D5 2:E5 2.5:F#5',
            '0:G5 1:F#5 2:E5',
            '0:F#5 1:A4 2:C#5',
            '0:D5',
            '0:D5 1:G4 1.5:F#4 2:G4',
            '0:E5 1:G4 1.5:F#4 2:G4',
            '0:D5 1:C5 2:B4',
            '0:A4 0.5:G4 1:F#4 1.5:G4 2:A4',
            '0:D4 0.5:E4 1:F#4 1.5:G4 2:A4 2.5:B4',
            '0:C5 1:B4 2:A4',
            '0:B4 0.5:D5 1:G4 2:F#4',
            '0:G4',
        ],
        chords=[(0, M), (0, M), (5, M), (0, M), (2, m), (0, M), (7, M), (7, M),
                (0, M), (0, M), (5, M), (0, M), (2, m), (0, M), (7, M), (0, M),
                (0, M), (7, M), (9, m), (2, M), (7, M), (2, M), (2, M), (7, M),
                (0, M), (5, M), (0, M), (7, M), (7, M), (2, m), [(0, M), (7, M)], (0, M)],
    ),
    dict(
        level=3, name='Elise', tonic='A', mode=MINOR, bpm=108, beats=3,
        composer='L. van Beethoven', piece='Für Elise, WoO 59 (1810)',
        source='Mutopia Project, fur_Elise_WoO59',
        groove='waltz',
        # its motifs are split by a sixteenth rest: A4 (eighth), rest, C4
        breath=1.5,
        mood='Für Elise in 3/8, counted in eighths: the theme twice, the bright middle part, and the theme again.',
        colors=['#d6c2ff', '#5a3f8f', '#0f0920'],
        bars=[
            # the theme (it starts with its pickup E D# at the end of the last bar)
            '0:E5 0.5:D#5 1:E5 1.5:B4 2:D5 2.5:C5',
            '0:A4 1.5:C4 2:E4 2.5:A4',
            '0:B4 1.5:E4 2:G#4 2.5:B4',
            '0:C5 1.5:E4 2:E5 2.5:D#5',
            '0:E5 0.5:D#5 1:E5 1.5:B4 2:D5 2.5:C5',
            '0:A4 1.5:C4 2:E4 2.5:A4',
            '0:B4 1.5:E4 2:C5 2.5:B4',
            '0:A4 2:E5 2.5:D#5',
            # again, then into the middle part
            '0:E5 0.5:D#5 1:E5 1.5:B4 2:D5 2.5:C5',
            '0:A4 1.5:C4 2:E4 2.5:A4',
            '0:B4 1.5:E4 2:G#4 2.5:B4',
            '0:C5 1.5:E4 2:E5 2.5:D#5',
            '0:E5 0.5:D#5 1:E5 1.5:B4 2:D5 2.5:C5',
            '0:A4 1.5:C4 2:E4 2.5:A4',
            '0:B4 1.5:E4 2:C5 2.5:B4',
            '0:A4 1.5:B4 2:C5 2.5:D5',
            # the middle part
            '0:E5 1.5:G4 2:F5 2.5:E5',
            '0:D5 1.5:F4 2:E5 2.5:D5',
            '0:C5 1.5:E4 2:D5 2.5:C5',
            '0:B4 1.5:E4 2:E5',
            '0.5:E5 1:E6 2.5:D#5',
            '0:E5 1.5:D#5 2:E5 2.5:D#5',
            # and the theme once more
            '0:E5 0.5:D#5 1:E5 1.5:B4 2:D5 2.5:C5',
            '0:A4 1.5:C4 2:E4 2.5:A4',
            '0:B4 1.5:E4 2:G#4 2.5:B4',
            '0:C5 1.5:E4 2:E5 2.5:D#5',
            '0:E5 0.5:D#5 1:E5 1.5:B4 2:D5 2.5:C5',
            '0:A4 1.5:C4 2:E4 2.5:A4',
            '0:B4 1.5:E4 2:C5 2.5:B4',
            '0:A4 2:E5 2.5:D#5',
        ],
        chords=[(7, M), (0, m), (7, M), (0, m), (7, M), (0, m), (7, M), (0, m)] * 2
               + [(3, M), (10, M), (0, m), (7, M), (7, M), (7, M)]
               + [(7, M), (0, m), (7, M), (0, m), (7, M), (0, m), (7, M), (0, m)],
    ),
    dict(
        level=4, name='Night Music', tonic='G', mode=MAJOR, bpm=104, beats=4,
        composer='W. A. Mozart', piece='Eine kleine Nachtmusik, K. 525, first movement (1787)',
        source='Mutopia Project, eine-kleine-nachtmusik-mvt1',
        groove='four',
        mood='The opening of Eine kleine Nachtmusik, the first violin part up to its first stop. Trills left out.',
        colors=['#ffc8dd', '#8f3f63', '#1c0812'],
        bars=[
            '0:G5 1.5:D5 2:G5 3.5:D5',
            '0:G5 0.5:D5 1:G5 1.5:B5 2:D6',
            '0:C6 1.5:A5 2:C6 3.5:A5',
            '0:C6 0.5:A5 1:F#5 1.5:A5 2:D5',
            '0:G5 1:G5 2.5:B5 3:A5 3.5:G5',
            '0:A5 0.5:F#5 1:F#5 2.5:A5 3:C6 3.5:F#5',
            '0:A5 0.5:G5 1:G5 2.5:B5 3:A5 3.5:G5',
            '0:A5 0.5:F#5 1:F#5 2.5:A5 3:C6 3.5:F#5',
            '0:G5 0.5:G5 1:F#5 1.5:E5 1.75:F#5 2:G5 2.5:G5 3:A5 3.5:G5 3.75:A5',
            '0:B5 0.5:B5 1:C6 1.5:B5 1.75:C6 2:D6',
            '0:D5 2:E5',
            '0:C5 1:C5 2:B4 3:B4',
            '0:A4 1:A4 2:G4 2.5:F#4 3:E4 3.5:F#4',
            '0:G4 1:A4 2:B4',
            '0:D5 2:E5',
            '0:D5 0.5:C5 1:C5 1.5:C5 2:C5 2.5:B4 3:B4 3.5:B4',
            '0:B4 0.5:A4 1:A4 1.5:A4 2:G4 2.5:F#4 3:E4 3.5:F#4',
            '0:G4',
        ],
        chords=[(0, M), [(0, M), (7, M)], (7, M), (7, M), (0, M), (7, M), (0, M), (7, M),
                (0, M), [(0, M), (7, M)], [(0, M), (5, M)], [(7, M), (0, M)], (7, M), (0, M),
                [(0, M), (5, M)], [(7, M), (0, M)], (7, M), (0, M)],
    ),
    dict(
        level=5, name='Turkish March', tonic='A', mode=MINOR, bpm=112, beats=4,
        composer='W. A. Mozart', piece='Rondo alla Turca, Piano Sonata No. 11, K. 331 (1783)',
        source='Mutopia Project, KV331_3_RondoAllaTurca',
        ice_bias=1,
        groove='drive',
        mood='The Rondo alla Turca theme, counted in eighths: the A minor tune, the C major answer, and the tune again.',
        colors=['#c9e4ff', '#34557a', '#060d18'],
        bars=[
            '0:C5 2:D5 2.5:C5 3:B4 3.5:C5',
            '0:E5 2:F5 2.5:E5 3:D#5 3.5:E5',
            '0:B5 0.5:A5 1:G#5 1.5:A5 2:B5 2.5:A5 3:G#5 3.5:A5',
            '0:C6 2:A5 3:C6',
            '0:B5 1:A5 2:G5 3:A5',
            '0:B5 1:A5 2:G5 3:A5',
            '0:B5 1:A5 2:G5 3:F#5',
            '0:E5 2:E5 3:F5',
            '0:G5 1:G5 2:A5 2.5:G5 3:F5 3.5:E5',
            '0:D5 1:G4 2:E5 3:F5',
            '0:G5 1:G5 2:A5 2.5:G5 3:F5 3.5:E5',
            '0:D5 2:C5 3:D5',
            '0:E5 1:E5 2:F5 2.5:E5 3:D5 3.5:C5',
            '0:B4 1:E4 2:C5 3:D5',
            '0:E5 1:E5 2:F5 2.5:E5 3:D5 3.5:C5',
            '0:B4 2:B4 2.5:A4 3:G#4 3.5:A4',
            '0:C5 2:D5 2.5:C5 3:B4 3.5:C5',
            '0:E5 2:F5 2.5:E5 3:D#5 3.5:E5',
            '0:B5 0.5:A5 1:G#5 1.5:A5 2:B5 2.5:A5 3:G#5 3.5:A5',
            '0:C6 2:A5 3:B5',
            '0:C6 1:B5 2:A5 3:G#5',
            '0:A5 1:E5 2:F5 3:D5',
            '0:C5 2:B4 3.5:A4 3.75:B4',
            '0:A4 2:B4 2.5:A4 3:G#4 3.5:A4',
        ],
        chords=[(0, m), (0, m), (0, m), (0, m), (7, m), (7, m), [(7, m), (2, M)], (7, m),
                (3, M), (10, M), (3, M), [(10, M), (0, m)], (0, m), (7, M), (0, m), (7, M),
                (0, m), (0, m), (0, m), (0, m), [(0, m), (7, M)], [(0, m), (5, m)], [(0, m), (7, M)], (0, m)],
    ),
    dict(
        level=6, name='Mountain King', tonic='B', mode=MINOR, bpm=116, beats=4,
        # 4 passes would be 2:13 of the same 16 bars
        plays=3,
        composer='E. Grieg', piece='In the Hall of the Mountain King, Peer Gynt (1875)',
        source='Mutopia Project, Dans_l_antre_du_roi_de_la_montagne',
        ice_bias=1,
        groove='drive',
        mood='The troll march: the low tune, the same an octave up, then the F# major turn low and high.',
        colors=['#ff8a5c', '#7a2a12', '#170603'],
        bars=[
            '0:B3 0.5:C#4 1:D4 1.5:E4 2:F#4 2.5:D4 3:F#4',
            '0:F4 0.5:C#4 1:F4 2:E4 2.5:C4 3:E4',
            '0:B3 0.5:C#4 1:D4 1.5:E4 2:F#4 2.5:D4 3:F#4 3.5:B4',
            '0:A4 0.5:F#4 1:D4 1.5:F#4 2:A4',
            '0:B4 0.5:C#5 1:D5 1.5:E5 2:F#5 2.5:D5 3:F#5',
            '0:F5 0.5:C#5 1:F5 2:E5 2.5:C5 3:E5',
            '0:B4 0.5:C#5 1:D5 1.5:E5 2:F#5 2.5:D5 3:F#5 3.5:B5',
            '0:A5 0.5:F#5 1:D5 1.5:F#5 2:A5',
            '0:F#4 0.5:G#4 1:A#4 1.5:B4 2:C#5 2.5:A#4 3:C#5',
            '0:D5 0.5:A#4 1:D5 2:C#5 2.5:A#4 3:C#5',
            '0:F#4 0.5:G#4 1:A#4 1.5:B4 2:C#5 2.5:A#4 3:C#5',
            '0:D5 0.5:A#4 1:D5 2:C#5',
            '0:F#5 0.5:G#5 1:A#5 1.5:B5 2:C#6 2.5:A#5 3:C#6',
            '0:D6 0.5:A#5 1:D6 2:C#6 2.5:A#5 3:C#6',
            '0:F#5 0.5:G#5 1:A#5 1.5:B5 2:C#6 2.5:A#5 3:C#6',
            '0:D6 0.5:A#5 1:D6 2:C#6',
        ],
        chords=[(0, m), [(2, M), (1, M)], (0, m), (3, M)] * 2 + [(7, M)] * 8,
    ),
]

BY_LEVEL = {s['level']: s for s in CLASSICAL}

if __name__ == '__main__':
    for s in CLASSICAL:
        p = build(s)['tune']
        ms = [x for _, _, x, _ in p['notes']]
        loop = len(s['bars']) * s['beats'] * 60 / s['bpm']
        print(s['level'], s['name'], len(s['bars']), 'bars', len(ms), 'notes', round(loop, 1), 's',
              round(len(ms) / loop, 2), 'notes/s, peak', round(max_rate(s), 2), 'range', min(ms), max(ms), 'ice from', p['iceFrom'])
