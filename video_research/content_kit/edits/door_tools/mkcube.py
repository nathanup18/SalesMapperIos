import numpy as np, sys
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def cube(sig, lin):
    E = (np.exp((sig - c_) / a_) + b_) / 12; N = 33; v = np.linspace(0, 1, N)
    b, g, r = np.meshgrid(v, v, v, indexing='ij'); rgb = np.stack([r, g, b], -1).reshape(-1, 3)
    l = lin(rgb) @ M.T * E
    e = np.where(l <= 1 / 12, np.sqrt(3 * np.clip(l, 0, None)), a_ * np.log(np.clip(12 * l - b_, 1e-9, None)) + c_)
    return np.clip(e, 0, 1)
srgb = lambda x: np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)
g24 = lambda x: x ** 2.4
ref = np.loadtxt('sdr2hlg.cube', skiprows=1)
for nm, f in [('srgb', srgb), ('g24', g24)]:
    for s in (0.70, 0.72, 0.75, 0.78):
        print(nm, s, np.abs(cube(s, f) - ref).max().round(4))
if len(sys.argv) > 2:
    c = cube(float(sys.argv[2]), srgb if sys.argv[3] == 'srgb' else g24)
    open(sys.argv[1], 'w').write('LUT_3D_SIZE 33\n' + ''.join(f'{x:.6f} {y:.6f} {z:.6f}\n' for x, y, z in c))
