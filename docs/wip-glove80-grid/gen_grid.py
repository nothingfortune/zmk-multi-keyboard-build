#!/usr/bin/env python3
# WIP — glove80 layer "grid" formatter prototype.
# Renders one glove80 layer file as a uniform-width, left-aligned column grid with an
# aligned LABEL comment row above each binding row (MoErgo-default style; see
# docs/glove80defaultlayout.keymap lines ~334-341).
#
# STATUS: prototype, base layer only. NOT yet sync-stable (see NOTES.md "Blocker").
# Run from repo root:  python3 docs/wip-glove80-grid/gen_grid.py  -> writes /tmp/base_uniform.dtsi
#
# Bindings are read from the *current* board file (so they stay correct/in order); the
# per-key LABELS are read from `git show HEAD:<file>` (the box-comment version still in git),
# extracted from the │ ... │ cells. Both are placed on an 18-column physical grid derived
# from boards/glove80/positions.dtsi.
import re, subprocess, math

TARGET = 'boards/glove80/layers/base.dtsi'   # generalize this to loop all layers later

# --- 1) physical grid map: position index -> (grid_row, grid_col) from positions.dtsi ---
pos_txt=open('boards/glove80/positions.dtsi').read()
idx_to_rc={}; COL={'C6':0,'C5':1,'C4':2,'C3':3,'C2':4,'C1':5}; RHCOL={'C1':12,'C2':13,'C3':14,'C4':15,'C5':16,'C6':17}
for m in re.finditer(r'#define\s+POS_(LH|RH)_(\w+?)\s+(\d+)', pos_txt):
    hand,name,i=m.group(1),m.group(2),int(m.group(3))
    mt=re.match(r'C(\d)R(\d)(i?)$',name)
    if mt:
        c,r,inner='C'+mt.group(1),int(mt.group(2)),mt.group(3)
        if inner: row=4; col={('LH','C1'):6,('LH','C2'):7,('LH','C3'):8,('RH','C3'):9,('RH','C2'):10,('RH','C1'):11}[(hand,c)]
        else: row=r; col=COL[c] if hand=='LH' else RHCOL[c]
        idx_to_rc[i]=(row,col); continue
    mt=re.match(r'T(\d)$',name)
    if mt: idx_to_rc[i]=(5,{('LH','T1'):6,('LH','T2'):7,('LH','T3'):8,('RH','T3'):9,('RH','T2'):10,('RH','T1'):11}[(hand,'T'+mt.group(1))])
assert len(idx_to_rc)==80

# --- 2) parse bindings (in order) and labels (in order) ---
def binds(text):
    blk=re.search(r'bindings\s*=\s*<(.*?)>\s*;',text,re.S).group(1); blk=re.sub(r'/\*.*?\*/',' ',blk,flags=re.S); blk=re.sub(r'//[^\n]*',' ',blk)
    out,cur=[],None
    for t in blk.split():
        if t.startswith('&'):
            if cur: out.append(cur)
            cur=t
        else: cur=(cur+' '+t) if cur else t
    if cur: out.append(cur)
    return out

B=binds(open(TARGET).read())
head=subprocess.run(['git','show',f'HEAD:{TARGET}'],capture_output=True,text=True).stdout
L=[m.group(0)[1:-1].strip() for m in re.finditer('│[^│]*│',head)]   # label cells from box-comment version
assert len(B)==80 and len(L)==80, (len(B),len(L))

# --- 3) uniform column width = longest binding + 10% (left-aligned) ---
# NOTE: for the next sync NOT to re-pad this, W must be >= go60's slot width for every
# mapped position (go60 normal slots reach ~88). See NOTES.md.
maxlen=max(len(b) for b in B)
W=math.ceil(maxlen*1.1)
print(f"longest mapping = {maxlen} chars -> column width W = {W} (+10%)")

gb={r:{} for r in range(6)}; gl={r:{} for r in range(6)}
for i in range(80): r,c=idx_to_rc[i]; gb[r][c]=B[i]; gl[r][c]=L[i]

def line(cells):
    return ''.join(cells.get(c,'').ljust(W) for c in range(18)).rstrip()

ROWS=['Row 1 — function row','Row 2 — number row','Row 3 — top alpha row','Row 4 — home row',
      'Row 5 — bottom alpha + inner columns','Row 6 — bottom mods + thumb cluster + arrows']
out=['/* glove80 — LAYER_Base (row-interleaved; shared positions synced from boards/go60/layers/base.dtsi) */','',
     '        LAYER_Base {','            bindings = <']
for r in range(6):
    out += ['', '/* '+ROWS[r]+' */', '/*  '+line(gl[r])+'  */', '    '+line(gb[r])]   # label row MUST be closed with */
out += ['            >;','        };']
open('/tmp/base_uniform.dtsi','w').write('\n'.join(out)+'\n')
print('wrote /tmp/base_uniform.dtsi')
