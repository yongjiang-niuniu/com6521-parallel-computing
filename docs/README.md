# Parallel computing documentation

The [project overview](../README.md) introduces the three workloads and the OpenMP/CUDA design choices.

| Guide | Use it to |
| --- | --- |
| [Build and recovery](BUILD_AND_RECOVERY.md) | Set up Windows or Linux, select inputs and understand original compiler settings. |
| [Results and evidence](RESULTS_AND_EVIDENCE.md) | Read the historical benchmark matrix, profiling scope and reference edge cases. |
| [Attribution](ATTRIBUTION.md) | Distinguish student implementations, course framework and bundled libraries. |
| [Original report](../submitted/comcuda_report.pdf) | Read the complete submitted design and performance discussion. |
| [Verification record](verification.json) | Inspect the original-file, framework and 512-window checks. |

## Implementation and provenance

- [Assembled project](../project/) contains the executable harness and working source layout; [submitted files](../submitted/) preserve the exact original deliverables.
- [Submission record](../archive/submission_record.json) identifies the official ZIP and member hashes.
- [Framework provenance](../archive/framework_provenance.json) records the official starter revision and the two-file overlay.

Recorded GPU measurements belong to the submitted report. The archive checks establish preservation and the stated limited reference comparison, not a new run of the NVIDIA benchmark matrix.
