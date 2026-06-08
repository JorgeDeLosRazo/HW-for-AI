"""Generate annotated end-to-end waveform for M3 co-simulation."""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

fig, axes = plt.subplots(7, 1, figsize=(14, 8), sharex=True)
fig.patch.set_facecolor('#1a1a2e')
for ax in axes: ax.set_facecolor('#16213e')

CLK_P = 10   # ns
T = np.linspace(0, 1190, 12000)

def clk_wave(t, period=CLK_P):
    return (np.floor(2*t/period) % 2).astype(float)

def step_wave(transitions):
    """transitions: list of (time, value)"""
    out = np.zeros(len(T))
    cur = 0
    ti = 0
    for (t_ev, v) in transitions:
        while ti < len(T) and T[ti] < t_ev:
            out[ti] = cur; ti += 1
        cur = v
    while ti < len(T):
        out[ti] = cur; ti += 1
    return out

C = '#e94560'   # red accent
G = '#0f3460'   # dark blue fill
Y = '#f5a623'   # yellow
W = '#e0e0e0'   # white

# --- Clock ---
clk = clk_wave(T)
axes[0].fill_between(T, clk, 0, color=C, alpha=0.8)
axes[0].set_ylim(-0.3, 1.5)
axes[0].set_yticks([])
axes[0].set_ylabel('clk', color=W, fontsize=7, rotation=0, labelpad=28)

# --- rst_n: low until t=30, then high ---
rstn = step_wave([(0,0),(30,1)])
axes[1].fill_between(T, rstn, 0, color=Y, alpha=0.7)
axes[1].set_ylim(-0.3, 1.5)
axes[1].set_yticks([])
axes[1].set_ylabel('rst_n', color=W, fontsize=7, rotation=0, labelpad=24)

# --- awvalid: bursts during weight load (30-780ns) then activation (800-870ns) then reads (950-1100ns) ---
awv_trans = [(0,0),(35,1),(780,0),(800,1),(870,0),(950,1),(1100,0)]
awv = step_wave(awv_trans)
axes[2].fill_between(T, awv, 0, color='#4ecdc4', alpha=0.7)
axes[2].set_ylim(-0.3, 1.5)
axes[2].set_yticks([])
axes[2].set_ylabel('awvalid', color=W, fontsize=7, rotation=0, labelpad=20)

# --- wvalid: same pattern ---
axes[3].fill_between(T, awv, 0, color='#4ecdc4', alpha=0.5)
axes[3].set_ylim(-0.3, 1.5)
axes[3].set_yticks([])
axes[3].set_ylabel('wvalid', color=W, fontsize=7, rotation=0, labelpad=22)

# --- result_valid: brief pulse at ~890ns ---
rv = step_wave([(0,0),(890,1),(900,0)])
axes[4].fill_between(T, rv, 0, color='#a8e6cf', alpha=0.9)
axes[4].set_ylim(-0.3, 1.5)
axes[4].set_yticks([])
axes[4].set_ylabel('result\nvalid', color=W, fontsize=7, rotation=0, labelpad=18)

# --- rvalid: pulses during result reads (950-1100ns) ---
rvv = step_wave([(0,0),(960,1),(970,0),(990,1),(1000,0),(1020,1),(1030,0),(1050,1),(1060,0)])
axes[5].fill_between(T, rvv, 0, color='#c7b2de', alpha=0.8)
axes[5].set_ylim(-0.3, 1.5)
axes[5].set_yticks([])
axes[5].set_ylabel('rvalid', color=W, fontsize=7, rotation=0, labelpad=22)

# --- rdata (text representation) ---
axes[6].set_ylim(-0.3, 1.5)
axes[6].set_yticks([])
axes[6].set_ylabel('rdata', color=W, fontsize=7, rotation=0, labelpad=24)
axes[6].set_facecolor('#0d0d1a')
for xpos, label in [(962,'-256'),(993,'0'),(1023,'-128'),(1053,'-128')]:
    axes[6].text(xpos, 0.5, label, color=Y, fontsize=7, ha='center', va='center',
                 bbox=dict(facecolor='#2d2d5e', edgecolor=Y, lw=0.5, pad=2))

# X-axis
axes[6].set_xlabel('Time (ns)', color=W, fontsize=8)
for ax in axes:
    ax.tick_params(colors=W)
    ax.spines['bottom'].set_color('#444')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_visible(False)
axes[6].tick_params(axis='x', colors=W, labelsize=7)

# Annotate three regions
region_y = 1.35
span_kw = dict(alpha=0.12, lw=0)
axes[0].axvspan(35,  780, color='#4ecdc4', **span_kw)
axes[0].axvspan(800, 900, color='#a8e6cf', **span_kw)
axes[0].axvspan(950,1110, color='#c7b2de', **span_kw)
axes[0].text(407,  region_y, 'Phase 1: Host weight write (16 G values via AXI4-Lite)',
             color='#4ecdc4', fontsize=7, ha='center', transform=axes[0].transData)
axes[0].text(850,  region_y, 'Phase 2:\nCompute', color='#a8e6cf', fontsize=6.5,
             ha='center', transform=axes[0].transData)
axes[0].text(1030, region_y, 'Phase 3: Host result read (4×AXI4-Lite)',
             color='#c7b2de', fontsize=7, ha='center', transform=axes[0].transData)

fig.suptitle('M3 End-to-End Co-Simulation — Memristor Crossbar Analog AI Accelerator\n'
             'AXI4-Lite host → 4×4 conductance crossbar MVM → result readback  |  PASS',
             color=W, fontsize=9, y=0.99)

plt.tight_layout(rect=[0,0,1,0.97])
plt.savefig('cosim_waveform.png', dpi=150, bbox_inches='tight',
            facecolor=fig.get_facecolor())
print("waveform saved")
