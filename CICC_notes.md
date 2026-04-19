# Custom Integrated Circuit Conference

### Wafer Scale Integration
* All weights stored in GB/s of on-chip SRAM, multiple wafers used for large models
* Very large internal bandwidths


### Flying Bitline
Flrying bitline improves density by ~5% compared to conventional multi-bank design without flying bitline
* Does add more parasitic capacitance

### Ways to Scale SRAM
* Moving from FinFET -> Nanosheet since nanosheet can be stacked
    * Nanosheet is improving scaling
    * 
* The vertically stacked CMOS architecture provides  ~1.5x - 2x higher density

## Oter Types of RAM
* MRAM is good for car or phones
NOTE: All other forms of RAM is slower than SRAM. 


# Diffusion and Drift in MOS transistors
Presentation by Ali Sheikholeslami (ali@ece.utoronto.ca). Writes Circuit Intuition (SSCS Magazine)
* Operational One Transistor
* Accelerator Complex (XCD)
* Future of AI accelerators will combine die of different techonologies
* GPUs and AI racks are very power hungry
* 

### Physical Unclonable Function (PUF)
Imagine each chip has a fingerprint . We need tpo think of a circuit next to chip that will measure all the random things happening  to chip as key---1024 bits, <br>
Things that happen to chip are random so fingerprint will be unique.<br>
Don't want to have fingerprint on IoT device on the filed,<br>
Let chip generate everytime you want to access it.<br>
WE still don't want the IoT device to be power hungry. It has to be low-power,<br>
You can use any random process during fabrication, but you typically use something that requires the least circuitry to record <br>


* IoT devices need circuits to generate fingerprints for higher level authentication
* Must use low energy as it is used for every authentication


### Inversions of Pinch-off Region
* Weak Inversion: When looking at I-V characteristic in a log scale, the space between curves is larger
* Medium Inversion: When looking at the I-V characteristic plot in a log scale, the space between curves is moderate
* Stron Inversion: When looking at the I-V characteristic plot in a log scale, the space between curves is really small

### Transistor's Off Current


### How to Reduce Off Current
* If you want a transistor to not have a large off current increase $$V_T$$
* 

### Summary
* Weak inversion uses low current and is slower but is very efficient. So if you need answer very fast we use strong inversion.
* Square law equations for MOS is only goo if you have a long channel. 
    * There is a whole region below threshold voltage usually ignore but is used often for low poer applications


# C over ID Algorithm for Device Sizing
* Armin Tajalli (armin.tajall@)
* Every transistor can be modeled by its transconductance
* Parasitic Caps limit the bandwidth (load capacitance, and self-loading capacitance) $$C_S$$. Note that self-loading capacitance is also calle dparasitic capacitance (we don't want it). Load capacitance however is good, wee need some of it $$C_L$$


### How can You Optimize Analog Circuits
* gm/ID algorithm
* EKV algorithm


### Challenges and Solutions



* For minimizing power consumption maximize gm/ID
* In practice the self-loading capacitance cannot be ignored (especially when gm/ID is high). DON"T IGNORE IT!!!
* Relationship between self-loading capacitance and transconductance cannot be ignored
* Self-loading capacitance is a function of gm/ID
* At strong inversion self-loading capacitance becomes larger and transconductance gets lower
* 

### Examples
* $$\frac{\del C_s}{\del Gm} = \frac{1}{\omega}_u$$
    * $$G_m = \frac{gm}{I_D}$$

* Scalability property: the optimal operating point is independent of the load capacitance
* Device characterization guideline: 


* **Example 1):** Passive bandwidth extension

## Types of Noise
* Flicker noise 
* Thermal Noise
* Phase noise


# IC Rules of Thumbs
* **Presenter**: Antonio Liscidini (antonio.liscidini@utoronto.ca)
* **NOTE**: These are rules of thumbs so numbers could be a little different 
* 
* **MOSFET Rule of Thumbs**: 
    * Dennard Sacling: Shrink by a factor of k allos density to grow as $$K^2$$ and speed increases by k.
        * constant electric field
        * constant $$\mu C_{ox} V_{OV}$$
        * After 2005 Dennard scaling stopped however for different engineering reasons
    * **Channel Sheet Resistance**: At maximum overdrive $$R_x$$ is roughly $$5k\Omega$$ per squrae, stable across CMOS nodes from 180nm FinFETs
        * Caveats:
            * Gate oxide reliability: VGS must stay within the maximum rated voltage
            * PMOS mobility can be weaker: PMOS Ry can be up to ~2 higher
            * Body effect 
    * **Current Desnity ID/W**: In saturation for max Ft the current density ID/W is about 200uA/um, stable across technology nodes> 
        * Useful for quick sizing: Need 1mA? minimum W = 5um, in any modern node.
        * Technology portable: sizing intuiotion transfers from one node to another
        * Caveats:
            * In subthreshold ID/W drops by orders of magnitude
            * PMOS is weaker : ~2 - 3x lower current density at the sam eoverdrive
            * Velocity Saturation
    * **Gate Capacitance Cgg/W**: Cgg/W is roughly 1-2fF/um stable across CMOS technology nodes
        * Dynamic power: knwoing Cgg allows to estoimate switching power
        * Driving sizing: load capacitance = Wl x 
        * Caveats:
            * Miller effect: Cgd amplifier by voltage gain. Effective input can exceed Cgg
            * Bias dependence: Cgg largest in stron inversion (1-2fF/um aplies there)
            * Parasitic: ina dvanced nodes, routing/junction caps often dominate
            * FinFET 3D: Fin sidewall and fri -----
    * **Transconductance Efficiency gm/ID**: The amacimum gm/ID is close to weak inversion and is equal to  20-25 $$V^{-1}$$ 
        * In weak inversion MOSFET becomes a BJT so that gm=ID/VT
        * Power Budget ceiling: min current ID. You cannot do better
        * Caveats:
            * speed penalty: weak inversion gives macimum gm/ID but min fT
            * Transition region: in moderat inversion, exact gm/ID requires look up tables
    * **The 1k1p Rule**: 
        * $$1k\Omega \times 1pF$$ gives fp = 160MHz
        * Caveats: 
            * Parasitic Capacticance: parasitics easily add fF to intended load
            * Miller effect: feedback C across gain -A appears as C(1+A) at input
    * **The 1n1p Rule**: 
        * 1nH x 1pF gives f0 = 5GHz

    * 

