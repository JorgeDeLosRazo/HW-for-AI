
# CMAN Codefest #8

You are designing the off-chip output interface for a spiking neural network (SNN) accelerator. The SNN has N = 1024 output neurons, each with a mean firing rate of f = 50 Hz (spikes per second). Spikes are
communicated to the host using Address-Event Representation (AER): when a neuron fires, the chip emits a packet containing the neuron address plus framing overhead. There is no clock-driven frame; packets are emitted asynchronously as spikes occur. Assume firing is independent across neurons (Poisson-like statistics).

1) **Compute the mean aggregate spike rate R (spikes/second) for the whole output layer. Show the formula and substitute values: R = N × f.**

$$R = 1024 \times 50Hz = 51200~\text{(spikes/s)}$$

2) **Each AER packet contains a 10-bit neuron address (since log₂(1024) = 10), a 6-bit timestamp, and a 4-bit framing/parity overhead, for 20 bits per packet total. Compute the mean required AER bandwidth B in bits/second and convert to Mbit/s. Show the formula: B = R × 20.**

$$B = R \times 20 = 51,200~\text{(spikes/s)} \times 20 = 1.024~\text{(MBits/s)}$$

3) **Compare your B to each of the standard interfaces from the M1 table: SPI (≤50 Mbit/s), I²C (≤3.4 Mbit/s), AXI4-Lite (assume 100 Mbit/s effective for a narrow bus). For each interface, state whether it can sustain the mean rate, and identify which is the lowest-complexity interface that suffices**

The three interfaces (SPI, $I^2C$, and AXI4-Lite) can sustain the mean rate, however the interface with the lowest-complexity that would suffice is $I^2C$ ($\geq 3.4~\text{(MBits/s)}$) since it only requires two wires (SDA and SCL).


4) **Bursts matter. Suppose stimulus arrives that causes 25% of the 1024 neurons to fire within a 1 ms window (synchronous burst). Compute the peak instantaneous bandwidth required in Mbit/s during that window. Compare to the mean bandwidth from task 2 and identify the burst-to-mean ratio. State whether the interface chosen in task 3 can absorb the burst, or whether buffering is required (and roughly how deep).**

5) **Frame-based comparison. A conventional (non-AER) readout would sample all 1024 neurons every 1 ms regardless of activity, sending 1 bit per neuron per sample. Compute the frame-based bandwidth in Mbit/s and the AER-to-frame bandwidth ratio at the mean firing rate. State the firing rate f_crossover at which AER and frame-based bandwidths are equal (set them equal and solve for f). Briefly state in one sentence what this implies for when AER is the right choice.**