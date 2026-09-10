# Parallel Computing with GPUs · COM6521

OpenMP and CUDA implementations of three workloads: counting glider patterns in a Game of Life image, building integer histograms and applying a greyscale emboss stencil. The project compares how independent work, reductions and contended updates behave on multicore CPUs and GPUs.

中文概述：本项目用 OpenMP 与 CUDA 实现滑翔机计数、直方图和浮雕图像处理，比较不同并行模式的设计与性能。原始提交、官方框架和报告已完整保留；报告中的 GPU 测量与本机完成的恢复检查分别说明。

## Project at a glance

| Field | Details |
| --- | --- |
| Course | COM6521 / COM4521, University of Sheffield |
| Project type | Individual parallel-programming coursework |
| Technology | C, CUDA C++, OpenMP, Visual Studio / Makefile |
| Workloads | 3×3 window classification, many-to-few accumulation and image stencil processing |
| Status | Complete source tree assembled from the verified course starter and unchanged submitted implementations; NVIDIA execution not rerun during recovery |

## What it does

The supplied executable loads images or integer data, selects a CPU/OpenMP/CUDA implementation, compares results with the serial reference and optionally benchmarks repeated calls.

| Algorithm | Input and output |
| --- | --- |
| Count Gliders | Scan 3×3 image windows and return the number matching one of 16 reference patterns. |
| Histogram | Count integer values in `[0, 255]` into bins of a selected width. |
| Emboss | Convert each 3×3 RGB neighbourhood to a greyscale stencil response, producing an image two pixels smaller in each dimension. |

## Repository guide

| Location | Contents |
| --- | --- |
| [project/](project/) | Complete project layout: implementations, reference, harness, headers, build files and sample image |
| [project/src/](project/src/) | Serial reference and submitted OpenMP/CUDA algorithms |
| [submitted/](submitted/) | The two implementation files and seven-page report exactly as submitted |
| [archive/](archive/) | Original submission ZIP, official starter, brief and provenance records |
| [docs/](docs/README.md) | Build instructions, results interpretation, attribution and verification evidence |

## Getting started

For the recorded Windows build, use Visual Studio C/C++ toolset **v143** with **CUDA Toolkit 12.6** and the project's OpenMP configuration. From a Visual Studio developer command prompt at the repository root:

```bat
msbuild project\assignment.sln /p:Configuration=Release /p:Platform=x64
cd project
x64\Release\assignment.exe CPU CG cg_16_in.png
x64\Release\assignment.exe OPENMP CG cg_16_in.png
x64\Release\assignment.exe CUDA CG cg_16_in.png
```

The supplied Linux Makefile uses GCC with OpenMP and `nvcc`:

```sh
cd project
make release
./bin/release/assignment CUDA H 12345 1000000 10 --bench
```

The histogram seed `12345` is an example, not a recovered original experiment seed. `--bench` runs 100 repetitions. The complete harness links CUDA even when a command selects CPU or OpenMP.

Use the [build guide](docs/BUILD_AND_RECOVERY.md) for the full argument syntax, Emboss input requirements, CUDA architecture settings and differences between Windows and Linux compiler flags. The commands follow the recovered project; they have not been run end to end on NVIDIA hardware during recovery.

## Design and method

| Algorithm | OpenMP approach | CUDA approach |
| --- | --- | --- |
| Count Gliders | Flatten window coordinates, encode nine-bit masks and reduce a statically scheduled loop. | Grid-stride scanning, constant-memory masks, shared-memory block reduction and one global atomic addition per block. |
| Histogram | Accumulate into private per-thread bins, then merge. | Accumulate into shared per-block bins with atomics, then merge into global bins. |
| Emboss | Collapse the two output-coordinate loops so each iteration computes one pixel. | Use 16×16 thread blocks, with one thread per output pixel. |

Every CUDA wrapper allocates device memory, copies input, launches the kernel, copies results back and frees its allocations. Buffers are not reused between calls. This makes wrapper overhead part of the reported timing. The submitted algorithms use no Thrust or CUB.

## Results and verification

**Historical report evidence:** the report records 48 validated benchmark cases, averaging 100 runs per selected implementation on an Intel i9-14900HX and NVIDIA RTX 4060 Laptop GPU, using Release x64 / CUDA 12.6.

| Input | Serial CPU | OpenMP | CUDA |
| --- | ---: | ---: | ---: |
| Count Gliders, 2048×2048 tiled image | 710.702 ms | 6.501 ms | 1.250 ms |
| Histogram, 16,000,000 integers, bin width 10 | 27.415 ms | 14.236 ms | 9.187 ms |
| Emboss, 2048×2048 RGB image | 104.178 ms | 18.814 ms | 3.515 ms |

**Recovery checks:** all 25 starter files match their official upstream revision; only the two implementation files differ in the assembled tree. The serial reference compiled with Apple clang, and its classifier matched both submitted mask tables for all **512 possible binary 3×3 windows**. Local includes, Visual Studio source references and the Makefile Release plan were checked.

The 512-window check does not execute OpenMP regions or CUDA kernels. No NVIDIA benchmark was rerun during recovery or this documentation refresh. [Results and evidence](docs/RESULTS_AND_EVIDENCE.md) distinguishes end-to-end timings from kernel-only profiling and links the preserved verification record.

## Limitations

- The large glider speedup combines parallel execution with cheaper mask classification; it is not a hardware-only comparison. Small inputs can be slower in parallel.
- Histogram aggregation still involves contention. Its returned-length convention follows the original reference, including an edge-bin issue explained in the results guide.
- Original measurement logs, custom large-image generators and the original histogram seeds are not recovered. The report alone does not reproduce the complete benchmark matrix.
- Nsight Compute hardware counters were unavailable in the reported experiment. The paper does not establish measured occupancy, cache hit rate or memory throughput.

## Attribution and provenance

Yongjiang Liu's student deliverables are `openmp.c`, `cuda.cu` and the report. The reference implementation, harness and build framework are supplied course material. The assembled tree preserves that boundary, and the original report's workflow and AI-assistance statement remain intact.

The official starter snapshot matches upstream commit `fb649d39e8637e552dbe56a096ece1f34b092d36`. Source archives, hashes and retained third-party notices are documented in [attribution](docs/ATTRIBUTION.md) and [framework provenance](archive/framework_provenance.json). This repository preserves the recovered work without reconstructing an invented development history.
