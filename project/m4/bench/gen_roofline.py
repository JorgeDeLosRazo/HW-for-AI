"""Generate final roofline plot for M4."""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

fig, ax = plt.subplots(figsize=(10, 6))
fig.patch.set_facecolor('#1a1a2e')
ax.set_facecolor('#16213e')

# Roofline parameters
compute_roof_cpu  = 0.230  # TFLOP/s
compute_roof_accel = 0.64  # TOPS (measured)
compute_roof_scale = 256   # TOPS (projected 64x64 crossbar, for reference)
bw_cpu  = 34.1  # GB/s (i5-8350U DDR4-2400 dual channel)
bw_accel = 0.64/8.0 * 1e3  # effective BW roof for accel (TOPS/AI × 1e3 GB/s scale)

ai = np.logspace(-1, 3, 1000)

# CPU roofline
cpu_roof = np.minimum(compute_roof_cpu, bw_cpu * ai / 1e3)
ax.loglog(ai, cpu_roof * 1e3, color='#4ecdc4', lw=2, label='CPU roofline (i5-8350U, 230 GFLOP/s)')

# Accelerator compute roof line
accel_roof = np.minimum(compute_roof_accel, bw_accel * ai / 1e3)
ax.loglog(ai, accel_roof * 1e3, color='#e94560', lw=2, linestyle='--',
          label='M4 accelerator compute roof (0.64 TOPS)')

# Projected scale (dashed)
proj_roof = np.full_like(ai, compute_roof_scale)
ax.loglog(ai, proj_roof, color='#f5a623', lw=1.5, linestyle=':',
          label='Projected 64×64 crossbar (256 TOPS)')

# Points
# M1 CPU measured
ax.scatter([52.3], [142], color='#4ecdc4', s=120, zorder=5, marker='o')
ax.annotate('M1 CPU baseline\n142 GFLOP/s @ AI=52.3', xy=(52.3, 142),
            xytext=(15, 30), textcoords='offset points',
            color='#4ecdc4', fontsize=8,
            arrowprops=dict(arrowstyle='->', color='#4ecdc4', lw=1))

# M4 accelerator measured
ax.scatter([8.0], [640], color='#e94560', s=180, zorder=5, marker='*')
ax.annotate('M4 crossbar\n640 GOPS @ AI=8.0', xy=(8.0, 640),
            xytext=(15, -40), textcoords='offset points',
            color='#e94560', fontsize=8,
            arrowprops=dict(arrowstyle='->', color='#e94560', lw=1))

# M1 design target (hypothetical)
ax.scatter([52.3], [2000], color='#a8e6cf', s=100, zorder=5, marker='^')
ax.annotate('M1 design target\n2 TOPS @ AI=52.3\n(hypothetical)', xy=(52.3, 2000),
            xytext=(-80, 15), textcoords='offset points',
            color='#a8e6cf', fontsize=8,
            arrowprops=dict(arrowstyle='->', color='#a8e6cf', lw=1))

ax.set_xlabel('Arithmetic Intensity (FLOP/byte)', color='white', fontsize=11)
ax.set_ylabel('Performance (GFLOP/s or GOPS)', color='white', fontsize=11)
ax.set_title('Final Roofline Plot — Memristor Crossbar Analog AI Accelerator (M4)',
             color='white', fontsize=12, pad=12)
ax.tick_params(colors='white', labelsize=9)
ax.spines['bottom'].set_color('#555')
ax.spines['left'].set_color('#555')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.grid(True, alpha=0.2, color='#888')
ax.set_xlim(0.1, 1000)
ax.set_ylim(1, 1e6)

legend = ax.legend(loc='upper left', fontsize=8, facecolor='#0d0d1a',
                   edgecolor='#555', labelcolor='white')

plt.tight_layout()
plt.savefig('roofline_final.png', dpi=150, bbox_inches='tight',
            facecolor=fig.get_facecolor())
print("roofline saved")
