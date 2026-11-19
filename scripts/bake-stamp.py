"""Emboss the name stamp into the awake power-bar fill frames.

Usage: python bake-stamp.py <baseline-project> <project> [darken]

The stamp (artwork/stamp-source.jpg) is trimmed to its ink, scaled to the bar height,
centered on the bar, and drawn as a darker shade of each frame's own fill
color. It only appears where the fill is, so it fades out as the charge drops
below the stamp's left edge.
"""
import sys
import numpy as np
from PIL import Image

base, proj = sys.argv[1], sys.argv[2]
DARKEN = float(sys.argv[3]) if len(sys.argv) > 3 else 0.25
SPR = 'assets/432x514-amazfit-bip-max'

# ink mask from the light-grey stamp on near-white paper
import os
stamp = next(p for p in (f'{proj}/artwork/stamp-source.jpg', f'{proj}/stamp-source.jpg') if os.path.exists(p))
gray = np.asarray(Image.open(stamp).convert('L')).astype(np.float64)
ink = np.clip((248 - gray) / (248 - 150), 0, 1)
ys, xs = np.nonzero(ink > 0.1)
ink = ink[ys.min():ys.max() + 1, xs.min():xs.max() + 1]

FW, FH = 250, 20
SH = FH - 2
SW = round(ink.shape[1] * SH / ink.shape[0])
mask = np.asarray(Image.fromarray((ink * 255).astype(np.uint8)).resize((SW, SH), Image.LANCZOS)) / 255
X0, Y0 = (FW - SW) // 2, (FH - SH) // 2
print(f'stamp {SW}x{SH} at x{X0}-{X0 + SW - 1} ({X0 / FW:.0%}-{(X0 + SW) / FW:.0%} of the bar)')

for i in range(101):
    f = np.asarray(Image.open(f'{base}/{SPR}/battery-level-{i}.png').convert('RGBA')).astype(np.float64)
    region = f[Y0:Y0 + SH, X0:X0 + SW]
    shade = 1 - DARKEN * mask * (region[..., 3] > 0)
    region[..., :3] *= shade[..., None]
    Image.fromarray(f.round().astype(np.uint8), 'RGBA').save(f'{proj}/{SPR}/battery-level-{i}.png')
