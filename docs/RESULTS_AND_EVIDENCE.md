# Results and evidence

The source for this document is the [submitted report](../submitted/comcuda_report.pdf). Numerical values here are transcribed from that report. They have not been regenerated in the current archive environment.

## Recorded evaluation setup

| Item | Reported configuration |
| --- | --- |
| Build | Visual Studio, Release x64 |
| CUDA toolkit | 12.6 |
| CPU | Intel Core i9-14900HX |
| GPU | NVIDIA GeForce RTX 4060 Laptop GPU |
| GPU memory | 8188 MiB |
| NVIDIA driver | 595.79 |
| Timing | Supplied harness `--bench`, average of 100 runs |
| Correctness reference | Supplied serial CPU implementation |
| Reported validation outcome | All 48 benchmark cases passed |

The report also states that the Release build completed without warnings or errors. Original compiler logs, per-case benchmark output and profiler capture files are not present in the submitted ZIP, so those claims remain report evidence.

## Benchmark inputs

| Algorithm | Inputs described in the report |
| --- | --- |
| Count Gliders | Supplied `cg_16_in.png`; deterministic tiled glider images at 256×256, 1024×1024 and 2048×2048 |
| Histogram | Pseudo-random integer arrays of length 4096, 1,000,000 and 16,000,000; bin widths 10, 17 and 64 |
| Emboss | Deterministic RGB images at 256×256, 1024×1024 and 2048×2048 |

The report describes 48 benchmark cases over this matrix. The recovered framework includes the sample glider image and a seeded histogram generator. The seeds used in the original measurements, custom tiled/RGB generators and generated large images are not included in the submission. Recreating similarly sized inputs would not establish that they are byte-identical to the original benchmark data.

## How to interpret the timing comparison

The report's main comparison is the full harness call. CUDA calls include device allocation, host-to-device transfer, launch, result transfer and deallocation. This is consistent with the submitted CUDA wrappers, which perform these operations on every invocation.

For the 2048×2048 glider input, the report gives 710.702 ms for the CPU reference, 6.501 ms for OpenMP and 1.250 ms for CUDA. These comparisons combine algorithmic restructuring with parallelism: both submitted versions use 16 precomputed glider masks, whereas the report describes repeated transformations in the serial reference. The large ratio should therefore not be described as a hardware-only speedup.

For the tiny supplied glider image, the reported times are 0.054 ms, 0.222 ms and 0.441 ms respectively. Parallel overhead exceeds the useful work in that case. Histogram's many-to-few updates also behave differently from independent window or stencil computations, so a single headline speedup would not represent the whole project.

## Profiling evidence and limits

The report says Nsight Compute could not access hardware counters and returned `ERR_NVGPUCTRPERM`. It consequently does not claim measured occupancy, cache-hit rates or memory throughput. Nsight Systems supplied the kernel timing summary reproduced in figure 4:

| CUDA kernel | Input | Reported representative duration |
| --- | --- | --- |
| `countGlidersKernel` | 2048×2048 tiled glider image | 126.430 µs |
| `histogramKernel` | 16,000,000 integers, bin width 10 | 259.227 µs |
| `embossKernel` | 2048×2048 deterministic RGB image | 206.588 µs |

These kernel durations exclude much of the full wrapper work and must not replace the end-to-end benchmark times. The figure shows one recorded launch per representative profiling case, rather than a distribution of repeated profiler measurements.

## Report map

| PDF pages | Material |
| --- | --- |
| 1–2 | Methodology, machine, inputs and OpenMP design |
| 3–4 | CUDA design and wrapper trade-offs |
| 4–6 | Runtime, speedup, histogram sensitivity and profiling figures |
| 7 | Limitations, project workflow and original AI-assistance statement |

All seven pages and both submitted source files were inspected while archiving. Their algorithm descriptions agree at the structural level: mask-based classification and reduction, private/shared histograms, and a fixed 3×3 emboss stencil.

During recovery, the unchanged course `cpu.c` was compiled on the archive machine. Its glider function was evaluated for all 512 possible binary 3×3 windows and compared with the 16 masks used by both submitted implementations: every result matched. This focused check validates the mask table against the supplied reference; it does not execute OpenMP parallel regions or CUDA kernels. The [verification record](verification.json) separates this result from the historical benchmark claims.

The recovered reference has a histogram convention worth preserving explicitly: the returned length is `ceil(255 / bin_width)`, while 255 itself is an allowed input. When 255 is divisible by the bin width, its edge bin falls outside that returned prefix. The submitted versions allocate an extra internal bin and return/copy the reference-length prefix. Passing the original comparison therefore does not establish a conventional inclusive-range histogram for every bin width. This archive preserves the original reference and submitted behaviour rather than silently changing their contract.
