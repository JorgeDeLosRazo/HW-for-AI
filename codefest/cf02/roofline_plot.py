import numpy as np
import matplotlib.pyplot as plt

peak_compute    = 10_000   # GFLOP/s  (10 TFLOP/s)
peak_bandwidth  = 320      # GB/s
ridge_point_x   = peak_compute / peak_bandwidth  # 31.25 FLOP/byte

# Arithmetic intensity range (log-spaced)
ai = np.logspace(-2, 4, 1000)  # 0.01 to 10,000 FLOP/byte

# Roofline: min of memory-bound and compute-bound ceilings
performance = np.minimum(peak_bandwidth * ai, peak_compute)

fig, ax = plt.subplots(figsize=(8, 6))

ax.loglog(ai, performance, 'b-', linewidth=2, label='Roofline')

# Mark the ridge point
ax.axvline(x=ridge_point_x, color='gray', linestyle='--', linewidth=1)
ax.plot(ridge_point_x, peak_compute, 'ro', markersize=8, label=f'Ridge point ({ridge_point_x} FLOP/byte)')

# Annotations
ax.annotate('Memory-bound', xy=(0.05, peak_bandwidth * 0.05),
            xytext=(0.05, peak_bandwidth * 0.12),
            fontsize=9, color='blue')
ax.annotate('Compute-bound', xy=(ridge_point_x * 2, peak_compute * 0.85),
            fontsize=9, color='blue')

ax.set_xlabel('Arithmetic Intensity (FLOP/byte)', fontsize=12)
ax.set_ylabel('Performance (GFLOP/s)', fontsize=12)
ax.set_title('Roofline Model\nPeak Compute: 10 TFLOP/s | Peak BW: 320 GB/s', fontsize=13)
ax.legend(fontsize=10)
ax.grid(True, which='both', linestyle=':', alpha=0.6)
ax.set_xlim(1e-2, 1e4)
ax.set_ylim(1, 1e5)

plt.tight_layout()
plt.savefig('roofline.png', dpi=150)
plt.show()
