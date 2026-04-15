"""
Roofline plot for GPT-2 Small dominant kernel (aten::addmm)
Target hardware: Intel Core i5-8350U (laptop CPU)
Hypothetical HW accelerator: custom matrix inference chip
"""
import numpy as np
import matplotlib.pyplot as plt
import os

# ── Hardware: Intel i5-8350U ──────────────────────────────────────────────────
# 4 cores × 2 FMAs × 8 FP32/FMA × 3.6 GHz = 230.4 GFLOP/s
# Dual-channel DDR4-2133: ~34 GB/s
cpu_peak_compute   = 230    # GFLOP/s
cpu_peak_bw        = 34     # GB/s
cpu_ridge          = cpu_peak_compute / cpu_peak_bw   # ≈ 6.76 FLOP/byte

# ── Hypothetical HW Accelerator ───────────────────────────────────────────────
# 8-core systolic array @ 2 TFLOP/s FP32, HBM2 on-chip @ 500 GB/s
hw_peak_compute    = 2000   # GFLOP/s  (2 TFLOP/s)
hw_peak_bw         = 500    # GB/s
hw_ridge           = hw_peak_compute / hw_peak_bw     # 4.0 FLOP/byte

# ── GPT-2 Small dominant kernel: aten::addmm (linear projections) ─────────────
# AI = 21,743 MFLOPs / 415.6 MB = 52.3 FLOP/byte  (see ai_calculation.md)
kernel_ai   = 52.3    # FLOP/byte
kernel_name = "GPT-2 addmm\n(linear proj.)"

# Attainable performance on each platform
cpu_attainable = min(cpu_peak_bw * kernel_ai, cpu_peak_compute)   # 230 GFLOP/s
hw_attainable  = min(hw_peak_bw  * kernel_ai, hw_peak_compute)    # 2000 GFLOP/s

# ── Plot ──────────────────────────────────────────────────────────────────────
ai_range = np.logspace(-1, 4, 2000)   # 0.1 to 10,000 FLOP/byte

def roofline(ai, peak_bw, peak_compute):
    return np.minimum(peak_bw * ai, peak_compute)

fig, ax = plt.subplots(figsize=(10, 7))

# CPU roofline
ax.loglog(ai_range, roofline(ai_range, cpu_peak_bw, cpu_peak_compute),
          'b-', linewidth=2.5, label=f'CPU Roofline (i5-8350U)')

# HW accelerator roofline
ax.loglog(ai_range, roofline(ai_range, hw_peak_bw, hw_peak_compute),
          'r--', linewidth=2.5, label=f'HW Accelerator Roofline (2 TFLOP/s, 500 GB/s HBM)')

# Ridge points
ax.axvline(x=cpu_ridge, color='blue', linestyle=':', linewidth=1, alpha=0.6)
ax.axvline(x=hw_ridge,  color='red',  linestyle=':', linewidth=1, alpha=0.6)

ax.plot(cpu_ridge, cpu_peak_compute, 'b^', markersize=9,
        label=f'CPU ridge point ({cpu_ridge:.1f} FLOP/byte, {cpu_peak_compute} GFLOP/s)')
ax.plot(hw_ridge,  hw_peak_compute,  'r^', markersize=9,
        label=f'HW ridge point ({hw_ridge:.1f} FLOP/byte, {hw_peak_compute} GFLOP/s)')

# Kernel on CPU roofline
ax.plot(kernel_ai, cpu_attainable, 'go', markersize=12, zorder=5,
        label=f'Kernel on CPU ({kernel_ai} FLOP/byte → {cpu_attainable} GFLOP/s)')
ax.annotate(f'{kernel_name}\n(CPU: {cpu_attainable} GFLOP/s)',
            xy=(kernel_ai, cpu_attainable),
            xytext=(kernel_ai * 0.15, cpu_attainable * 0.35),
            fontsize=9, color='green',
            arrowprops=dict(arrowstyle='->', color='green'))

# Kernel on HW accelerator roofline
ax.plot(kernel_ai, hw_attainable, 'rs', markersize=12, zorder=5,
        label=f'Kernel on HW accel. ({kernel_ai} FLOP/byte → {hw_attainable} GFLOP/s)')
ax.annotate(f'{kernel_name}\n(HW: {hw_attainable} GFLOP/s)',
            xy=(kernel_ai, hw_attainable),
            xytext=(kernel_ai * 3, hw_attainable * 0.55),
            fontsize=9, color='red',
            arrowprops=dict(arrowstyle='->', color='red'))

# Region labels
ax.text(0.2, cpu_peak_bw * 0.2 * 0.6, 'Memory-bound\nregion', fontsize=9,
        color='gray', style='italic')
ax.text(cpu_ridge * 1.5, cpu_peak_compute * 1.05, 'Compute-bound region',
        fontsize=9, color='gray', style='italic')

ax.set_xlabel('Arithmetic Intensity (FLOP/byte)', fontsize=13)
ax.set_ylabel('Performance (GFLOP/s)', fontsize=13)
ax.set_title(
    'Roofline Model — GPT-2 Small Inference\n'
    'CPU: Intel i5-8350U  |  HW Accel.: 2 TFLOP/s + 500 GB/s HBM',
    fontsize=13
)
ax.legend(fontsize=9, loc='upper left')
ax.grid(True, which='both', linestyle=':', alpha=0.5)
ax.set_xlim(1e-1, 1e4)
ax.set_ylim(1, 1e4)

plt.tight_layout()

out_path = os.path.join(os.path.dirname(__file__), "roofline_project.png")
plt.savefig(out_path, dpi=150)
print(f"Saved: {out_path}")
plt.close()
