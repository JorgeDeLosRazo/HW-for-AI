# Notes
Blah Blah

## Mutliply-Accumulate Operations (MACs)
This is one of the fundamental computational blocks of used to calculate weigted sums in neural networks.
 * It counts the mutlyply-add operations performed
 * FIXME

## Bytes Transferred in Neural Networks
The amount of data moved between memory (DRAM) and the processing unit (GPU/CPU/AI accelerator) during training or inference.


## Inference vs Training



## Intrinsic vs Designed Computation
* `Intrinsic`: The hardware itself finds the solution
    * Changing problem will require changing the hardware which makes it harder--less flexible
* `Designed`:Things like code that solve the problem
    * More flexible, meaming tweaking parameters is easier

## Why Design Something New?
* Data Locality: when we have off-chip memory there is high latency and requires high energy. It is better to have memroy on chip.
* Compute Closer to Physics: Blah

## What is a Computing Kernel?
In this context a compute kernel is a single computational routinethat runs on a processor (or GPU or some other HW)

## Arithmetic Intensity (AI)
Measures how much computation a program performs relative to how much data it moves
* $$I = \frac{\text{FLOPs}}{\text{bytes transferred}}
    * If $AI < 1$: moves more data than it computes
    * If $AI >1$: computation larger than the data movement
    * Unit is **FLOPs per byte** (FLOP/B)
* Used to characterize whether workload is bottlenecked by compute throughput or by memory badnwidth
    * A workload with **low AI** moves a lot of data relative to the work done
    * A workload with a **high AI** does a lot of computation per byte fetched

## General Matrix Multiply (GEMM)
Hello


## Kernel in Machine Learning
A kernel is a relatively straightforward function that operates on two vectors from the input space



## Convolutional Layer
Think of a convolutional layer as a filter being placed above an image


## Ridge Point
Optimal point were the memory-bandwith slope intersects the comput bound line

## Maximum Memory Bandwidth


## GPU
Used to parallelize.
Good for compute-intensive functions

### Single Instruction


## Tensor
It is a matrix with coordinates

### Tensor Cores
Operate on FP16 


## CUDA
Stands for Compute Unified Device Architecture. Is a parallel computing platform and programming model developed by NVIDIA.

## Warp
A warp is a group of threads that executes instructions simultaneously on a GPU 


# MAchine Lerning Fundamentals
NOTE: Machine Learning is a subset of Artificial Intelligence that focuses on developing algorithms that enable computers to learn from data.

<figure>
<img src="images/venn-diagram-AI-ML.png">
<figcaption> Image from <a href="https://www.blog.trainindata.com/machine-learning-fundamentals/">here</a></figcaption>
</figure>

