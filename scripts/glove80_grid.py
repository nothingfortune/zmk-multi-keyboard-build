#!/usr/bin/env python3
"""glove80_grid.py — normalize Glove80 layer files into a uniform aligned grid.

The Glove80 layer files (boards/glove80/layers/*.dtsi) are rendered as a fixed
18-column grid (6 left-hand columns | 6 center columns | 6 right-hand columns),
with one label-comment row sitting directly above each binding row so every key
is self-documenting and each label starts at the exact column of its binding.

Why this exists
---------------
The original files drifted: cells were padded inconsistently, so labels no longer
sat over their bindings. Hand-editing a column-aligned grid is error-prone, so this
script is the source of truth for the *formatting* (never the bindings — it only
re-lays-out the bindings already present in each file, and refuses to run if the
ordered &-token stream would change).

This is safe to run after scripts/keymapsync.sh: that script preserves each board's
own column widths (it no longer inherits go60's gap-inflated slot widths), so a
sync followed by this regenerate is stable and a re-sync is a byte-identical no-op.

Usage
-----
    python3 scripts/glove80_grid.py            # rewrite all 21 glove80 layers in place
    python3 scripts/glove80_grid.py FILE...    # rewrite specific files
    python3 scripts/glove80_grid.py --check     # exit 1 if any file is not normalized

Binding order must already match boards/glove80/positions.dtsi (positions 0..79,
row-interleaved). This script never reorders or edits binding text.
"""
import glob
import os
import re
import sys

W = 48          # uniform column width
INDENT = 4      # leading spaces on binding rows

# 18-column model: cols 0-5 = LH C6..C1 | 6-11 = center | 12-17 = RH C1..C6.
# Each row lists the columns it fills, in physical-position order (0..79).
FILLED = {
    0: [1, 2, 3, 4, 5, 12, 13, 14, 15, 16],                              # func (5+5)
    1: [0, 1, 2, 3, 4, 5, 12, 13, 14, 15, 16, 17],                       # number
    2: [0, 1, 2, 3, 4, 5, 12, 13, 14, 15, 16, 17],                       # top alpha
    3: [0, 1, 2, 3, 4, 5, 12, 13, 14, 15, 16, 17],                       # home
    4: list(range(18)),                                                   # bottom + inner (6+6+6)
    5: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],          # bottom mods + thumbs (5+6+5)
}
EXPECT = [10, 12, 12, 12, 18, 16]
ROW_DESC = [
    "Row 0 — function row",
    "Row 1 — number row",
    "Row 2 — top alpha row",
    "Row 3 — home row",
    "Row 4 — bottom row + inner columns",
    "Row 5 — bottom mods + thumb cluster",
]


def group_bindings(text):
    """Split a bindings block into complete '&behavior [params]' tokens."""
    out, cur = [], None
    for tk in text.split():
        if tk.startswith('&'):
            if cur is not None:
                out.append(cur)
            cur = tk
        else:
            cur = (cur + ' ' + tk) if cur else tk
    if cur is not None:
        out.append(cur)
    return out


def labels_of(line):
    """Extract per-cell labels from a label-comment row (base or box style)."""
    s = line.strip()
    s = re.sub(r'^/\*', '', s)
    s = re.sub(r'\*/$', '', s)
    if '│' in s:                                    # box style: │ label │ │ label │
        return [x.strip() for x in re.findall(r'│([^│]*)│', s)]
    return [p for p in re.split(r'\s{2,}', s.strip()) if p != '']        # base style


def parse(path):
    lines = open(path).read().split('\n')
    start = next(i for i, l in enumerate(lines)
                 if l.lstrip().startswith('/*') and re.search(r'Row\s*\d', l))
    close = next(i for i, l in enumerate(lines) if '>;' in l)
    preamble = lines[:start]
    while preamble and preamble[-1].strip() == '':
        preamble.pop()
    suffix = lines[close:]
    grid = lines[start:close]
    rows = []
    i = 0
    while i < len(grid):
        if grid[i].lstrip().startswith('/*') and re.search(r'Row\s*\d', grid[i]):
            i += 1
            while i < len(grid) and not grid[i].lstrip().startswith('/*'):
                i += 1
            label = grid[i]
            i += 1
            while i < len(grid) and '&' not in grid[i]:
                i += 1
            bind = grid[i]
            i += 1
            rows.append((label, bind))
        else:
            i += 1
    return preamble, suffix, rows


def render(cells_by_col, comment):
    buf = [' '] * (INDENT + 18 * W)
    if comment:
        buf[0], buf[1] = '/', '*'
    for col, text in cells_by_col.items():
        c = INDENT + col * W
        for k, ch in enumerate(text):
            buf[c + k] = ch
    line = ''.join(buf).rstrip()
    return line + ' */' if comment else line


def build(path):
    preamble, suffix, rows = parse(path)
    assert len(rows) == 6, f"{path}: found {len(rows)} rows, expected 6"
    out = list(preamble)
    for r, (labelline, bindline) in enumerate(rows):
        binds = group_bindings(re.sub(r'/\*.*?\*/', '', bindline))
        labs = labels_of(labelline)
        cols = FILLED[r]
        assert len(binds) == EXPECT[r], f"{path} row {r}: {len(binds)} bindings != {EXPECT[r]}"
        assert len(labs) == EXPECT[r], f"{path} row {r}: {len(labs)} labels != {EXPECT[r]}: {labs}"
        out.append('')
        out.append(f"/* {ROW_DESC[r]} */")
        out.append(render({cols[i]: labs[i] for i in range(len(cols))}, True))
        out.append(render({cols[i]: binds[i] for i in range(len(cols))}, False))
    out.append('')
    out += suffix
    res = '\n'.join(out)
    return res if res.endswith('\n') else res + '\n'


def tokens(text):
    return re.findall(r'&[A-Za-z0-9_]+', text)


def main(argv):
    check = '--check' in argv
    files = [a for a in argv if not a.startswith('--')]
    if not files:
        here = os.path.dirname(os.path.abspath(__file__))
        root = os.path.dirname(here)
        files = sorted(glob.glob(os.path.join(root, 'boards/glove80/layers/*.dtsi')))

    drift = False
    for path in files:
        original = open(path).read()
        result = build(path)
        # Safety: never let formatting change the ordered binding-token stream.
        if tokens(original) != tokens(result):
            print(f"REFUSING {path}: binding tokens would change", file=sys.stderr)
            drift = True
            continue
        if check:
            if original != result:
                print(f"not normalized: {path}")
                drift = True
        elif original != result:
            open(path, 'w').write(result)
            print(f"rewrote {path}")
    return 1 if drift else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
