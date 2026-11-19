"""Center TEMP, STEPS and DISTANCE artwork in their panels (v1.4.17 baseline).

Usage: python center-panels.py <baseline-project> <project>

- TEMP / STEPS / DISTANCE labels: horizontally centered between the icon's right
  edge and the panel's right border, where the readings are centered.
- Vertically the label + reading block is centered in the panel (TEMP up 8px,
  STEPS / DISTANCE down 4px); the thermometer moves down 4px to the panel middle.
- Vacated pixels are refilled with nearby parchment; colors are unchanged.
"""
import sys
import numpy as np
from PIL import Image

REL = 'assets/432x514-amazfit-bip-max/background.png'
base, proj = sys.argv[1], sys.argv[2]
src = np.asarray(Image.open(f'{base}/{REL}').convert('RGB')).astype(np.float64)
H, W, _ = src.shape
r, g, b = src[..., 0], src[..., 1], src[..., 2]
CLASSES = {
    'red':   (r > 150) & (r - g > 70),
    'blue':  (b > 100) & (b - r > 50),
    'green': (g > 90) & (g - r > 20) & (g - b > 5),
    'dark':  src.max(axis=2) < 80,
}


def dilate(mask, k):
    out = mask.copy()
    for _ in range(k):
        m = out.copy()
        m[1:] |= out[:-1]; m[:-1] |= out[1:]; m[:, 1:] |= out[:, :-1]; m[:, :-1] |= out[:, 1:]
        out = m
    return out


def element(box, cls):
    x0, y0, x1, y1 = box
    core = np.zeros((H, W), bool)
    core[y0:y1, x0:x1] = CLASSES[cls][y0:y1, x0:x1]
    ys, xs = np.nonzero(core)
    return {'core': core, 'bbox': (xs.min(), ys.min(), xs.max(), ys.max())}


E = {
    'temp':     element((349, 313, 410, 336), 'dark'),
    'steps':    element((80, 352, 176, 378), 'green'),
    'distance': element((280, 352, 362, 378), 'blue'),
}
# name -> (target center x, dy)
plan = {'temp': ((347 + 415) / 2, -8), 'steps': ((73 + 215) / 2, 4), 'distance': ((275 + 415) / 2, 4)}

# erase labels with nearby clean parchment
all_art = np.zeros((H, W), bool)
for c in CLASSES.values():
    all_art |= c
protected = dilate(all_art, 3)
filled = src.copy()
for name, e in E.items():
    e['erase'] = erase = dilate(e['core'], 3)
    ys, xs = np.nonzero(erase)
    best = None
    for k in range(14, 90, 2):
        for dx, dy in ((0, k), (0, -k), (k, 0), (-k, 0), (k, k), (-k, k), (k, -k), (-k, -k)):
            sy, sx = ys + dy, xs + dx
            if sy.min() < 0 or sx.min() < 0 or sy.max() >= H or sx.max() >= W:
                continue
            if not protected[sy, sx].any():
                best = (dx, dy)
                break
        if best:
            break
    filled[ys, xs] = src[ys + best[1], xs + best[0]]
out = filled.copy()

# thermometer: shift its block (icon with its parchment) down 4px
TX0, TY0, TX1, TY1 = 319, 266, 349, 324
out[TY0 + 4:TY1 + 4, TX0:TX1] = filled[TY0:TY1, TX0:TX1]

# paste labels at their new positions
for name, e in E.items():
    x0, y0, x1, y1 = e['bbox']
    X0, Y0, X1, Y1 = x0 - 3, y0 - 3, x1 + 4, y1 + 4
    p, bg = src[Y0:Y1, X0:X1], filled[Y0:Y1, X0:X1]
    d = np.linalg.norm(p - bg, axis=2)
    a = np.clip(d / np.percentile(d[e['core'][Y0:Y1, X0:X1]], 60), 0, 1) * e['erase'][Y0:Y1, X0:X1]
    a[a < 0.08] = 0
    fg = np.clip(np.where(a[..., None] > 0, bg + (p - bg) / np.maximum(a, 1e-6)[..., None], 0), 0, 255)
    cx, dy = plan[name]
    px = round(cx - (x0 + x1) / 2) + X0
    py = Y0 + dy
    h, w = a.shape
    out[py:py + h, px:px + w] = out[py:py + h, px:px + w] * (1 - a[..., None]) + fg * a[..., None]
    print(f'{name:9} x {x0}-{x1} -> center {cx}, dy {dy}')

Image.fromarray(np.clip(out, 0, 255).round().astype(np.uint8), 'RGB').save(f'{proj}/{REL}')
