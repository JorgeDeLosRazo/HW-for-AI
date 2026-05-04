"""Generate waveform.png from compute_core.vcd for M2 submission."""
import re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# ---------------------------------------------------------------------------
# Minimal VCD parser
# ---------------------------------------------------------------------------
def parse_vcd(filename, wanted_ids):
    """Return {id: [(time, value), ...]} for the listed VCD symbol IDs."""
    signals = {i: [] for i in wanted_ids}
    time = 0
    with open(filename) as f:
        in_defs = True
        for line in f:
            line = line.strip()
            if line.startswith('$enddefinitions'):
                in_defs = False
                continue
            if in_defs:
                continue
            if line.startswith('#'):
                time = int(line[1:])
                continue
            # Scalar: b... id  or  0id  or  1id  etc.
            m = re.match(r'^([01xzXZ])(.+)$', line)
            if m:
                val, sid = m.group(1), m.group(2).strip()
                if sid in signals:
                    signals[sid].append((time, int(val) if val in '01' else 0))
                continue
            # Vector: b<bits> <id>
            m = re.match(r'^b([01xzXZ]+)\s+(.+)$', line)
            if m:
                bits, sid = m.group(1), m.group(2).strip()
                if sid in signals:
                    try:
                        v = int(bits.replace('x','0').replace('z','0'), 2)
                    except ValueError:
                        v = 0
                    # Treat as signed 32-bit
                    if len(bits) == 32 and bits[0] == '1':
                        v -= (1 << 32)
                    signals[sid].append((time, v))
    return signals

def to_steps(signal, t_start, t_end, ps_per_ns):
    """Convert [(time_ps, val)] to step-function arrays for plotting."""
    times = [t / ps_per_ns for t, _ in signal]
    vals  = [v for _, v in signal]
    # Extend to t_end
    xs, ys = [t_start], [vals[0] if vals else 0]
    for t, v in zip(times, vals):
        if t_start <= t <= t_end:
            xs.append(t); ys.append(ys[-1])  # hold previous
            xs.append(t); ys.append(v)
    xs.append(t_end); ys.append(ys[-1])
    return xs, ys

# ---------------------------------------------------------------------------
# Signal IDs from VCD (tb_compute_core scope)
# ---------------------------------------------------------------------------
# From the VCD header:
#   ) = clk,  * = rst_n,  - = wload_en
#   ( = act_valid,  ' = act_last,  & = act_data
#   ! = result_valid,  % = result_0

VCD = 'compute_core.vcd'
IDS = {')', '*', '-', '(', "'", '&', '!', '%', '$', '#', '"'}
raw = parse_vcd(VCD, IDS)

# Timescale is 1ps; convert to ns
PS_PER_NS = 1000

# Focus on activation phase through result: roughly cycles 165..240 ns
# (weight loading ends around cycle 150ns, activation phase 160-240ns)
# Find the time range where act_valid fires:
act_valid_times = [t for t, v in raw['('] if v == 1]
if act_valid_times:
    t_act_start = min(act_valid_times) / PS_PER_NS
    t_act_end   = t_act_start + 60  # show 60 ns window
else:
    t_act_start, t_act_end = 0, 300

T0 = max(0, t_act_start - 20)   # a bit before first activation
T1 = t_act_end + 20

# ---------------------------------------------------------------------------
# Build step waveforms
# ---------------------------------------------------------------------------
def get_steps(sid, t0=T0*PS_PER_NS, t1=T1*PS_PER_NS):
    data = raw.get(sid, [])
    if not data:
        return [t0/PS_PER_NS, t1/PS_PER_NS], [0, 0]
    # Seed before first event
    first_val = data[0][1]
    # Find last value before t0
    seed_val = first_val
    for t, v in data:
        if t <= t0:
            seed_val = v
        else:
            break
    xs = [t0/PS_PER_NS]
    ys = [seed_val]
    for t, v in data:
        t_ns = t / PS_PER_NS
        if t_ns < T0 or t_ns > T1:
            continue
        xs.append(t_ns); ys.append(ys[-1])
        xs.append(t_ns); ys.append(v)
    xs.append(T1); ys.append(ys[-1])
    return xs, ys

def get_clk_steps():
    return get_steps(')')

# ---------------------------------------------------------------------------
# Plot
# ---------------------------------------------------------------------------
SIGNALS = [
    ('clk',          ')'),
    ('rst_n',        '*'),
    ('wload_en',     '-'),
    ('act_valid',    '('),
    ('act_last',     "'"),
    ('act_data',     '&'),
    ('result_valid', '!'),
    ('result_0',     '%'),
    ('result_1',     '$'),
    ('result_2',     '#'),
    ('result_3',     '"'),
]

fig, axes = plt.subplots(len(SIGNALS), 1,
                          figsize=(14, 8),
                          sharex=True,
                          gridspec_kw={'hspace': 0.05})

fig.suptitle('compute_core — Test 1: identity matrix, x=[1,2,3,4] → y=[1,2,3,4]',
             fontsize=11, fontweight='bold', y=0.98)

COLORS = {
    'clk': '#4a90d9', 'rst_n': '#e74c3c', 'wload_en': '#8e44ad',
    'act_valid': '#27ae60', 'act_last': '#f39c12', 'act_data': '#16a085',
    'result_valid': '#e74c3c', 'result_0': '#2980b9', 'result_1': '#27ae60',
    'result_2': '#8e44ad', 'result_3': '#c0392b',
}

for ax, (name, sid) in zip(axes, SIGNALS):
    xs, ys = get_steps(sid)
    color = COLORS.get(name, '#333')

    is_digital = name in ('clk', 'rst_n', 'wload_en', 'act_valid',
                          'act_last', 'result_valid')
    if is_digital:
        ax.step(xs, ys, where='post', color=color, linewidth=1.4)
        ax.fill_between(xs, 0, ys, step='post', color=color, alpha=0.18)
        ax.set_ylim(-0.2, 1.4)
        ax.set_yticks([0, 1])
        ax.set_yticklabels(['0', '1'], fontsize=7)
    else:
        # Analog / bus — draw as step with value labels
        ax.step(xs, ys, where='post', color=color, linewidth=1.6)
        ax.set_ylim(min(ys) - 1, max(ys) + 1 if max(ys) != min(ys) else 5)
        ax.set_yticks([])

    ax.set_ylabel(name, rotation=0, ha='right', va='center',
                  fontsize=8, labelpad=42)
    ax.set_xlim(T0, T1)
    ax.tick_params(axis='x', labelsize=7)
    ax.grid(axis='x', linestyle=':', alpha=0.4)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

    # Annotate bus signal transitions with their values
    if not is_digital:
        prev_v = None
        for i in range(1, len(xs)):
            if ys[i] != ys[i-1] and xs[i] != xs[i-1]:
                mid = (xs[i] + (xs[i+1] if i+1 < len(xs) else T1)) / 2
                v = ys[i]
                if v != prev_v:
                    ax.text(mid, max(ys)/2 + min(ys)/2,
                            str(v), fontsize=7, ha='center', va='center',
                            color=color, fontweight='bold')
                    prev_v = v

axes[-1].set_xlabel('Time (ns)', fontsize=9)

# Annotate key events
if act_valid_times:
    for ax in axes:
        ax.axvline(x=act_valid_times[0]/PS_PER_NS, color='gray',
                   linestyle='--', linewidth=0.8, alpha=0.6)
    axes[0].text(act_valid_times[0]/PS_PER_NS + 1, 1.1,
                 'activations start', fontsize=7, color='gray')

result_valid_times = [t for t, v in raw['!'] if v == 1]
if result_valid_times:
    for ax in axes:
        ax.axvline(x=result_valid_times[0]/PS_PER_NS, color='red',
                   linestyle='--', linewidth=0.8, alpha=0.5)
    axes[0].text(result_valid_times[0]/PS_PER_NS + 1, 1.1,
                 'result_valid', fontsize=7, color='red')

plt.tight_layout(rect=[0, 0, 1, 0.97])
plt.savefig('waveform.png', dpi=150, bbox_inches='tight')
print("Saved waveform.png")
