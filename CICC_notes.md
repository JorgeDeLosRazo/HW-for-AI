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

* IoT devices need circuits to generate fingerprints for higher level authentication
* Must use low energy as it is used for every authentication



