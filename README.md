# Parallel Computing with GPUs — COM6521

Yongjiang Liu's submitted OpenMP and CUDA implementations of three algorithms: Game of Life glider counting, integer histograms and greyscale image embossing. The project explores CPU reductions, private aggregation, GPU shared memory, atomics and stencil processing against a supplied serial reference.

The [seven-page report](submitted/comcuda_report.pdf) explains the design and records the original performance evaluation. The [OpenMP source](submitted/openmp.c) and [CUDA source](submitted/cuda.cu) are preserved exactly as submitted.

## Implemented algorithms

| Algorithm | OpenMP implementation | CUDA implementation |
| --- | --- | --- |
| Count Gliders | Encode each 3×3 cell window as a nine-bit mask, compare with 16 patterns and reduce the count over a statically scheduled loop. | Use grid-stride window scanning, constant-memory patterns, a shared-memory block reduction and one global atomic addition per block. |
| Histogram | Accumulate into one private histogram per CPU thread, then merge the bins. | Accumulate into a shared-memory histogram per block, then merge into global bins with atomics. |
| Emboss | Collapse the two output-coordinate loops; each iteration converts a 3×3 RGB neighbourhood to greyscale and applies the emboss stencil. | Use 16×16 thread blocks, with one thread computing each greyscale output pixel. |

The CUDA wrappers allocate, transfer, compute, copy results back and free memory on each call. They do not retain buffers between benchmark repetitions. Count Gliders and Emboss return early for images smaller than 3×3; histogram functions reject non-positive bin widths.

## Results recorded in the report

The report describes **48 benchmark cases**, validated against the supplied serial reference, with each selected implementation timed over **100 repetitions**. The recorded machine was an Intel i9-14900HX with an NVIDIA RTX 4060 Laptop GPU, using Visual Studio Release x64 and CUDA Toolkit 12.6.

| Input | Serial CPU | OpenMP | CUDA |
| --- | --- | --- | --- |
| Count Gliders, 2048×2048 tiled image | 710.702 ms | 6.501 ms | 1.250 ms |
| Histogram, 16,000,000 integers, bin width 10 | 27.415 ms | 14.236 ms | 9.187 ms |
| Emboss, 2048×2048 RGB image | 104.178 ms | 18.814 ms | 3.515 ms |

These are historical end-to-end harness measurements from the submitted report, not results rerun during archiving. The glider comparison includes the benefit of replacing the reference's transformation checks with mask matching as well as parallel execution. Small inputs can be slower in parallel, and histogram contention limits acceleration. See the [results and evidence notes](docs/RESULTS_AND_EVIDENCE.md) for the benchmark matrix and profiling limits.

## Building and running

The [complete project tree](project/) combines the official course starter with the two unchanged submitted implementation files. It includes the headers, serial reference, input/validation harness, Visual Studio solution, Linux Makefile and supplied glider sample. The original submission and starter archives are retained separately.

Open [project/assignment.sln](project/assignment.sln) for the original Windows build, or use the supplied Makefile on a suitable Linux CUDA system. The [build and recovery notes](docs/BUILD_AND_RECOVERY.md) provide exact sample commands, dependency details and the checks that were possible during archiving. The full OpenMP/CUDA program has not been rebuilt on NVIDIA hardware during this recovery.

## Preserved deliverables

| Path | Purpose |
| --- | --- |
| [submitted/openmp.c](submitted/openmp.c) | Original OpenMP implementation |
| [submitted/cuda.cu](submitted/cuda.cu) | Original CUDA implementation |
| [submitted/comcuda_report.pdf](submitted/comcuda_report.pdf) | Original report, including workflow and AI-assistance statement |
| [archive/COMCUDA_submission_draft_20260521_165303.zip](archive/COMCUDA_submission_draft_20260521_165303.zip) | Unchanged ZIP downloaded from the submitted Blackboard attempt |
| [archive/submission_record.json](archive/submission_record.json) | Submission provenance, archive hash and hashes of every extracted file |
| [project/](project/) | Official framework with only `src/openmp.c` and `src/cuda.cu` replaced by the submitted files |
| [archive/framework_provenance.json](archive/framework_provenance.json) | Official starter version, upstream commit, complete file hashes and assembly record |
| [docs/ATTRIBUTION.md](docs/ATTRIBUTION.md) | Student/framework boundary and retained third-party notices |

The course is COM6521, cross-listed with COM4521. Blackboard records assignment attempt 1 as submitted **21 May 2026 at 23:55 (UTC+8)**. The original ZIP filename contains `draft`; it was recovered from the officially submitted attempt and its filename is retained unchanged.

The serial reference, starter interfaces and validation framework belong to the supplied course project. The submitted report says implementation changes were confined to `openmp.c` and `cuda.cu`; this archive preserves that distinction and the original report's acknowledgements.

The official v7 starter ZIP matches all 25 files at upstream commit [`fb649d3`](https://github.com/RSE-Sheffield/COMCUDA_assignment_fe221142/commit/fb649d39e8637e552dbe56a096ece1f34b092d36). This is a verified recovery source, not proof of which starter revision was used for the original benchmark run. The archive commits record the preservation and assembly work at the time it was performed.
