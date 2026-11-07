"""The 10 level songs: their definitions, the melody writer, and the renderer.

Every song works like the game's current song (RhythmSongs): one 8 bar
backing loop as stems, and 8 bar melody phrases the shield plays. Every
phrase keeps the game's note counts (8 downbeats, 17 on-beat, 6 off-beat),
so the rhythm director and its density rules work unchanged.

  python3 songs.py OUT_DIR [--full] [--only 1,2]
"""
import json, os, subprocess, sys
import numpy as np
import soundfile as sf
import synth
import classical
from synth import *

MAJOR = [0, 2, 4, 5, 7, 9, 11]
MINOR = [0, 2, 3, 5, 7, 8, 10]
DORIAN = [0, 2, 3, 5, 7, 9, 10]
PHRYGIAN = [0, 1, 3, 5, 7, 8, 10]

# chords: (semitones above the tonic, 'M' or 'm'), one per bar, 4 bars twice
ORIGINAL_SONGS = [
    dict(level=1, name='Sprout', tonic='C', mode=MAJOR, bpm=100,
         chords=[(0, 'M'), (7, 'M'), (9, 'm'), (5, 'M')],
         groove='soft', mood='Gentle start. Half-time drums, round bass, the melody walks in small steps.',
         colors=['#7be0a6', '#2a6b54', '#071a14'], seed=11),
    dict(level=2, name='Frost Morning', tonic='G', mode=MAJOR, bpm=104,
         chords=[(0, 'M'), (9, 'm'), (5, 'M'), (7, 'M')],
         groove='pop', mood='Bright and icy. Light four-on-the-floor, bells up front, mostly ice notes.',
         colors=['#9fd8ff', '#2f5f8f', '#06121f'], seed=23, ice_bias=-3),
    dict(level=3, name='Campfire', tonic='A', mode=MINOR, bpm=108,
         chords=[(0, 'm'), (8, 'M'), (3, 'M'), (10, 'M')],
         groove='halftime', mood='Warm minor groove. Claps on 3, a low bass that bounces, mostly fire notes.',
         colors=['#ffb36b', '#8a3d17', '#1a0a04'], seed=37, ice_bias=4),
    dict(level=4, name='Drift', tonic='E', mode=MINOR, bpm=112,
         chords=[(0, 'm'), (5, 'm'), (8, 'M'), (7, 'M')],
         groove='syncop', mood='Floaty. Syncopated bass, a harmonic-minor turn at the end of every phrase.',
         colors=['#c3a6ff', '#4b2f8a', '#0e0820'], seed=41),
    dict(level=5, name='Hot Pan', tonic='D', mode=DORIAN, bpm=116,
         chords=[(0, 'm'), (5, 'M'), (0, 'm'), (10, 'M')],
         groove='funk', mood='Funky dorian. Off-beat hats and a busy bass, the first real workout.',
         colors=['#ff7a59', '#8c2a1a', '#1c0705'], seed=53, ice_bias=2),
    dict(level=6, name='Snow Globe', tonic='A#', mode=MAJOR, bpm=120,
         chords=[(0, 'M'), (4, 'm'), (9, 'm'), (5, 'M')],
         groove='four', mood='Sparkly major at the game\'s own tempo. Arp from the start, wide jumps.',
         colors=['#e6f3ff', '#5a7fa8', '#0a1424'], seed=67, ice_bias=-2),
    dict(level=7, name='Thaw', tonic='F', mode=MAJOR, bpm=124,
         chords=[(5, 'M'), (7, 'M'), (4, 'm'), (9, 'm')],
         groove='four', mood='Hopeful lift (IV V iii vi). Hot and cold trade the lead every bar.',
         colors=['#ffe08a', '#7a8f2e', '#141a06'], seed=79),
    dict(level=8, name='Steam', tonic='B', mode=MINOR, bpm=128,
         chords=[(0, 'm'), (8, 'M'), (10, 'M'), (7, 'M')],
         groove='drive', mood='Driving minor with a major V. 16th bass, long runs that cross the shield.',
         colors=['#7ff0e8', '#a33a7a', '#0d0a18'], seed=83),
    dict(level=9, name='Lava', tonic='C', mode=PHRYGIAN, bpm=132,
         chords=[(0, 'm'), (1, 'M'), (0, 'm'), (10, 'M')],
         groove='drive', mood='Dark phrygian. The half-step up to Db keeps it boiling, fast fire runs.',
         colors=['#ff4d2e', '#6e1208', '#140302'], seed=97, ice_bias=3),
    dict(level=10, name='Solstice', tonic='D', mode=MINOR, bpm=136,
         chords=[(0, 'm'), (8, 'M'), (3, 'M'), (10, 'M')],
         groove='epic', mood='The finale. Hot and cold together, everything plays, and the last choruses jump up a whole step.',
         colors=['#ffd36b', '#6aa8ff', '#05070f'], seed=101, modulate=2),
]

# Levels 1-6 play arranged public-domain classics (see classical.py)
SONGS = [classical.BY_LEVEL.get(s['level'], s) for s in ORIGINAL_SONGS]

BARS = 8
TONIC_MIDI = {k: v for k, v in synth.NOTE.items()}

# rhythm cells: beat positions in a bar. Every cell starts on the downbeat.
CELLS = [
    [0, 1, 2, 3], [0, 1, 2], [0, 2, 2.5], [0, 1, 2, 2.5], [0, 1.5, 2, 3],
    [0, 2, 3], [0, 1, 1.5, 2, 3], [0, 2], [0, 1, 2.5, 3], [0, 1, 3], [0, 0.5, 1, 2],
]


def tiers(cell):
    on = sum(1 for b in cell if b != 0 and b == int(b))
    off = sum(1 for b in cell if b != int(b))
    return on, off


def make_rhythm(rng, motif_bars=None):
    """8 cells with exactly 17 on-beat and 6 off-beat notes. Bars 4-5 repeat
    bars 0-1 (the motif), and the last bar ends on beat 3 (a pickup)."""
    for _ in range(200000):
        c = [CELLS[i] for i in rng.integers(0, len(CELLS), BARS)]
        if motif_bars is not None:
            c[0], c[1] = motif_bars
        c[4], c[5] = c[0], c[1]
        if 3 not in c[7]:
            continue
        on = sum(tiers(x)[0] for x in c)
        off = sum(tiers(x)[1] for x in c)
        if on == 17 and off == 6:
            return c
    raise RuntimeError('no rhythm')


def chord_pcs(tonic_pc, ch):
    root = (tonic_pc + ch[0]) % 12
    third = 4 if ch[1] == 'M' else 3
    return [root, (root + third) % 12, (root + 7) % 12]


def local_scale(tonic_pc, mode, chord):
    """The mode, bent to fit the bar's chord (a major V in minor raises the 7th)"""
    sc = [(tonic_pc + d) % 12 for d in mode]
    out = []
    for p in sc:
        clash = [c for c in chord if (c - p) % 12 in (1, 11)]
        out.append(clash[0] if clash and p not in chord and clash[0] not in sc else p)
    return sorted(set(out))


def contour(kind, x):
    """Target pitch offset (semitones from the centre) at x in [0,1)"""
    h = (x * 2) % 1  # each half of the phrase
    if kind == 'home':
        return 8 * np.sin(np.pi * h) - 3 + (2 if x > 0.75 else 0)
    if kind == 'valley':
        if x < 0.4:
            return 6 - 22 * x
        if x < 0.5:
            return -3 + 100 * (x - 0.4)
        return 7 - 12 * (x - 0.5)
    if kind == 'lift':
        return contour('home', x) + 5
    if kind == 'tense':
        return 9 + 3 * np.sin(np.pi * 4 * x)
    if kind == 'peak':
        q = (x * 4) % 1
        return 14 - 9 * q
    raise ValueError(kind)


def write_phrase(song, kind, rhythm, rng, centre):
    tonic_pc = synth.NOTE[song['tonic']]
    notes = []
    prev = None
    flat = [(bar, beat) for bar, cell in enumerate(rhythm) for beat in cell]
    for i, (bar, beat) in enumerate(flat):
        x = (bar + beat / 4) / BARS
        target = centre + contour(kind, x) + (0 if beat == 0 else (2.5 if i % 2 else -2.5))
        chord = chord_pcs(tonic_pc, song['chords'][bar % len(song['chords'])])
        sc = local_scale(tonic_pc, song['mode'], chord)
        if kind == 'tense' and beat == 0:
            # lean on the chord's 7th or 9th on the downbeat, the tension
            root = chord[0]
            pool = [(root + 10) % 12, (root + 2) % 12, chord[1]] if bar % 2 else chord
        elif beat == 0 or (beat == int(beat) and rng.random() < 0.6):
            pool = chord
        else:
            pool = sc
        if bar == BARS - 1 and beat == 3:
            # the pickup into the next phrase: the 2nd degree, or the 7th when it pulls
            pool = [(tonic_pc + 2) % 12]
            if (tonic_pc - 1) % 12 in chord:
                pool = [(tonic_pc - 1) % 12]
        cands = [m for m in range(48, 96) if m % 12 in pool]

        def cost(m):
            c = abs(m - target)
            if prev is not None:
                leap = abs(m - prev)
                c += 0.35 * max(0, leap - 5)
                if leap == 0:
                    c += 3.5 if beat != 0 else 1.5
                if beat != int(beat):
                    c += 0.6 * max(0, leap - 2)  # off-beats are passing notes
            return c + rng.random() * 0.8
        m = min(cands, key=cost)
        notes.append((bar, beat, int(m)))
        prev = m
    mids = sorted(m for _, _, m in notes)
    ice_from = mids[len(mids) // 2] + song.get('ice_bias', 0)
    return dict(name=kind, iceFrom=int(ice_from), notes=notes)


def design(song):
    if 'A' in song:
        return classical.build(song)
    rng = np.random.default_rng(song['seed'])
    tonic_pc = synth.NOTE[song['tonic']]
    # the centre: the tonic around G4-F#5, kept in the shield's range
    centre = 64 + (tonic_pc - 4) % 12
    motif = None
    phrases = {}
    for kind, shift in (('home', 0), ('valley', 0), ('lift', 0), ('tense', 0), ('peak', 0)):
        r = make_rhythm(rng, motif if kind in ('home', 'lift') else None)
        if kind == 'home':
            motif = (r[0], r[1])
        phrases[kind] = write_phrase(song, kind, r, rng, centre + shift)
    for p in phrases.values():
        on = sum(1 for _, b, _ in p['notes'] if b != 0 and b == int(b))
        off = sum(1 for _, b, _ in p['notes'] if b != int(b))
        assert (len(p['notes']), on, off) == (31, 17, 6), (song['name'], p['name'])
    return phrases


# ---------------------------------------------------------------- audio

def loop_seconds(song):
    return BARS * 4 * 60 / song['bpm']


def chord_voicing(tonic_pc, ch, shift=0):
    root = (tonic_pc + ch[0] + shift) % 12
    third = 4 if ch[1] == 'M' else 3
    bass_m = 36 + (root - 0) % 12  # C2..B2
    if bass_m > 43:
        bass_m -= 12
    low = 60 + (root - 0) % 12
    if low > 66:
        low -= 12
    return bass_m, [low, low + third, low + 7]


def stems(song, shift=0):
    bpm = song['bpm']
    beat = 60 / bpm
    bar_s = 4 * beat
    L = BARS * bar_s
    g = song['groove']
    tonic_pc = synth.NOTE[song['tonic']]
    out = {}
    for name in ('kick', 'claps', 'hats', 'hats16', 'bass', 'pad', 'arp'):
        m = Mix(L + 4)
        kicks = []
        for bar in range(BARS):
            b0 = bar * bar_s
            root, voicing = chord_voicing(tonic_pc, song['chords'][bar % len(song['chords'])], shift)
            if name == 'pad':
                m.add(pad(voicing, bar_s - 0.05, 0.9, cut=1400 if g in ('soft', 'halftime') else 1900), b0, 0, 0.55)
            for s16 in range(16):
                tt = b0 + s16 * beat / 4
                k_on = {
                    'soft': s16 in (0, 8, 10),
                    'halftime': s16 in (0, 6, 10),
                    'syncop': s16 in (0, 6, 8, 14),
                    'funk': s16 in (0, 3, 6, 10, 12),
                }.get(g, s16 % 4 == 0)
                if k_on:
                    kicks.append(tt)
                if name == 'kick' and k_on:
                    m.add(kick(), tt, 0, 0.7)
                if name == 'claps':
                    on = s16 == 8 if g in ('soft', 'halftime') else s16 % 8 == 4
                    if g == 'epic' and s16 == 14 and bar % 2:
                        on = True
                    if on:
                        m.add(clap(), tt, 0.1, 0.5)
                if name == 'hats':
                    if g == 'funk':
                        if s16 % 4 == 2:
                            m.add(hat(1, open_=True), tt, -0.25, 0.3)
                        elif s16 % 2 == 1:
                            m.add(hat(), tt, -0.25, 0.12)
                    elif g == 'soft':
                        if s16 % 4 == 2:
                            m.add(hat(), tt, -0.25, 0.2)
                    elif s16 % 2 == 0:
                        m.add(hat(1, open_=(s16 % 4 == 2)), tt, -0.25, 0.32 if s16 % 4 == 2 else 0.22)
                if name == 'hats16' and s16 % 2 == 1:
                    m.add(hat(), tt, 0.3, 0.14)
                if name == 'bass':
                    pat = {
                        'soft': {0: 0, 8: 0, 12: 7},
                        'pop': {i: 0 for i in range(0, 16, 2)},
                        'halftime': {0: 0, 3: 0, 6: 12, 10: 0, 14: 7},
                        'syncop': {0: 0, 3: 0, 6: 0, 10: 12, 12: 0, 14: 7},
                        'funk': {0: 0, 2: 12, 3: 0, 6: 10, 8: 0, 10: 12, 11: 0, 14: 7},
                        'four': {i: (12 if i in (6, 14) else 0) for i in range(0, 16, 2)},
                        'drive': {i: (12 if i % 8 == 6 else 0) for i in range(16)},
                        'epic': {i: (7 if i in (6, 14) else 0) for i in range(0, 16, 2)},
                    }[g]
                    if s16 in pat:
                        ln = beat / 4 - 0.02 if g == 'drive' else (beat * (1.6 if g == 'soft' else 0.5) - 0.04)
                        acc = 1.0 if s16 % 4 == 2 or g == 'soft' else 0.7
                        m.add(bass(root + pat[s16], ln, acc), tt, 0, 0.6)
                if name == 'arp':
                    tones = voicing + [voicing[0] + 12]
                    pat = [0, 1, 2, 3, 2, 1, 2, 3] if g not in ('soft', 'pop') else [0, 2, 1, 3, 0, 2, 1, 3]
                    step = 2 if g in ('soft', 'halftime') else 1
                    if s16 % step == 0:
                        m.add(pluck(tones[pat[s16 % 8]] + 12, 0.5, 0.6, 0.18), tt, 0.35 if s16 % 2 else -0.35, 0.5)
        st = m.stereo()
        if name in ('pad', 'bass', 'arp'):
            st = duck(st, kicks + [L], 0.45)
        st = reverb(st, 0.2)
        n = int(L * SR)
        o = st[:, :n].copy()
        tail = st[:, n:]
        k = min(tail.shape[1], n)
        o[:, :k] += tail[:, :k]
        out[name] = o
    return out


_note_cache = {}


def note_sound(midi, ice):
    key = (midi, ice)
    if key not in _note_cache:
        # like the game: ice rings as a bell, fire sounds an octave down
        _note_cache[key] = ice_hit(midi) if ice else fire_hit(midi - 12)
    return _note_cache[key]


def song_form(song):
    L = loop_seconds(song)
    n = max(8, round(180 / L))
    form = ['breather']
    while len(form) < n:
        i = len(form)
        f = i / n
        if abs(f - 0.6) < 0.5 / n * 1.2 and 'breather' not in form[2:]:
            form.append('breather')
        else:
            form.append('verse' if len(form) % 2 == 1 else 'chorus')
    form[-2:] = ['chorus', 'chorus']
    return form


STAGES = [
    (0.0, ['home', 'valley'], []),
    (0.3, ['home', 'lift', 'valley', 'lift'], []),
    (0.55, ['lift', 'tense'], ['hats16']),
    (0.75, ['tense', 'peak'], ['hats16', 'arp']),
]


def render(song, phrases, out_path, full=True):
    L = loop_seconds(song)
    beat = 60 / song['bpm']
    form = song_form(song) if full else ['chorus']
    base = stems(song)
    mod = song.get('modulate')
    up = stems(song, mod) if mod else None
    total = len(form) * L + 3.5
    mix = Mix(total)
    stage_i = 0
    plays = []
    for i, sec in enumerate(form):
        f = i / len(form)
        stage = [s for s in STAGES if f >= s[0]][-1] if full else STAGES[2]
        names, layers = stage[1], list(stage[2])
        if sec == 'chorus':
            layers = list(set(layers + ['hats16'] + (['arp'] if 'hats16' in stage[2] else [])))
        if song['groove'] in ('four', 'epic') and 'arp' not in layers and sec != 'breather':
            layers.append('arp')
        shift = mod if (mod and full and i >= len(form) - 2) else 0
        st = up if shift else base
        t0 = i * L
        for name, x in st.items():
            if name in ('hats16', 'arp') and name not in layers:
                continue
            if sec == 'breather' and name in ('kick', 'claps', 'hats', 'hats16', 'arp'):
                continue
            mix.add(x, t0, gain=1.0)
        ph = phrases[names[i % len(names)]]
        for bar, b, m in ph['notes']:
            tier = 0 if b == 0 else (1 if b == int(b) else 2)
            if sec == 'breather' and tier > 0:
                continue
            if sec == 'verse' and tier == 2:
                continue
            if full and f < 0.15 and tier == 2:
                continue
            ice = m >= ph['iceFrom']
            mix.add(note_sound(m + shift, ice), t0 + (bar * 4 + b) * beat, 0.25 if ice else -0.25, 0.55)
        plays.append(dict(section=sec, phrase=ph['name'], start=round(t0, 3)))
    if full:
        # the level-clear sting: the tonic chord rung out on top
        tonic = 72 + (synth.NOTE[song['tonic']] - 0) % 12 + (mod or 0)
        if tonic > 79:
            tonic -= 12
        third = 4 if song['mode'] == MAJOR else 3
        end = len(form) * L
        for k, m in enumerate([tonic, tonic + third, tonic + 7, tonic + 12]):
            mix.add(ice_hit(m), end + k * 0.06, 0, 0.5)
        mix.add(kick(), end, 0, 0.8)
        mix.add(riser(L / 4), len(form) * L - L / 4 - 0.0, 0, 0.6)
    st = master(mix.stereo(), total, fade_out=2.5 if full else 0.4, target=-15)
    w = out_path + '.wav'
    sf.write(w, st.T, SR)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', w, '-c:a', 'libmp3lame', '-b:a', '128k' if full else '96k', out_path], check=True)
    os.remove(w)
    return form, total


if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    full = '--full' in sys.argv
    only = None
    if '--only' in sys.argv:
        only = [int(x) for x in sys.argv[sys.argv.index('--only') + 1].split(',')]
    defs = []
    for song in SONGS:
        phrases = design(song)
        entry = {k: v for k, v in song.items() if k not in ('seed', 'A', 'B')}
        entry['mode'] = {tuple(MAJOR): 'major', tuple(MINOR): 'minor', tuple(DORIAN): 'dorian', tuple(PHRYGIAN): 'phrygian'}[tuple(song['mode'])]
        entry['loopSeconds'] = round(loop_seconds(song), 3)
        entry['form'] = song_form(song)
        entry['seconds'] = round(len(entry['form']) * loop_seconds(song), 1)
        entry['phrases'] = phrases
        defs.append(entry)
        if only and song['level'] not in only:
            continue
        slug = f"{song['level']:02d}-{song['name'].lower().replace(' ', '-')}"
        if full:
            form, total = render(song, phrases, f'{out}/{slug}.mp3', True)
            print(slug, 'full', round(total, 1), 's', form, flush=True)
        render(song, phrases, f'{out}/snip-{slug}.mp3', False)
        print(slug, 'snippet', flush=True)
    json.dump(defs, open(f'{out}/songs.json', 'w'), indent=1)
