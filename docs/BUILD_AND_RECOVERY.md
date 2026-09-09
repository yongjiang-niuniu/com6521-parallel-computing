# Build and recovery notes

## Complete project and original submission

The original [submitted ZIP](../archive/COMCUDA_submission_draft_20260521_165303.zip) contains exactly `comcuda_report.pdf`, `cuda.cu` and `openmp.c`, matching the deliverables required by the brief. The [extracted copies](../submitted/) are byte-identical.

The [project directory](../project/) restores the official v7 framework and overlays only `src/openmp.c` and `src/cuda.cu` with those submitted files. The remaining 23 files are identical to the downloaded starter. The [framework provenance](../archive/framework_provenance.json) records the hashes and upstream version. No build-file or header fix has been applied to the original framework.

## Windows: original build configuration

Open [project/assignment.sln](../project/assignment.sln) in Visual Studio with the C/C++ tools and CUDA Toolkit 12.6 installed. The recovered project selects toolset `v143`, uses `-openmp:llvm`, imports the CUDA 12.6 build customizations and sets 64-bit CUDA compilation. Select **Release | x64**.

Alternatively, from a Visual Studio developer command prompt at the repository root:

```bat
msbuild project\assignment.sln /p:Configuration=Release /p:Platform=x64
cd project
x64\Release\assignment.exe CPU CG cg_16_in.png
x64\Release\assignment.exe OPENMP CG cg_16_in.png
x64\Release\assignment.exe CUDA CG cg_16_in.png
x64\Release\assignment.exe CUDA H 12345 1000000 10 --bench
```

The histogram seed `12345` is a new example input for these instructions, not a recovered original benchmark seed. The executable paths follow the supplied solution's normal x64/Release layout; if the local Visual Studio configuration changes its output directory, use the built executable at that location.

The project has `compute_61,sm_61` as its CUDA generation setting and disables fused multiply-add with `-fmad=false`. Preserve the floating-point settings when checking exact Emboss results. Toolkit/GPU compatibility must be checked for the machine used to rebuild; the report records the RTX 4060 Laptop GPU and toolkit 12.6 but does not preserve every original workstation setting.

## Linux: supplied Makefile

The original Makefile uses GCC with OpenMP and NVIDIA `nvcc`. From the repository root:

```sh
cd project
make release
./bin/release/assignment CPU CG cg_16_in.png
./bin/release/assignment OPENMP CG cg_16_in.png
./bin/release/assignment CUDA CG cg_16_in.png
./bin/release/assignment CUDA H 12345 1000000 10 --bench
```

The Makefile defaults to `CUDA_ARCH=61` and allows a command-line override for the target compute capability. Use a CUDA architecture supported by the installed toolkit and GPU. The supplied Linux flags differ from the Visual Studio project, including the absence of the latter's `-fmad=false`; a Linux result is not automatically a reproduction of the reported Windows build. The complete harness still links CUDA even when an individual command selects CPU or OpenMP.

## Runtime interface

The recovered `internal/main.cu` accepts:

```text
assignment <CPU|OPENMP|CUDA> <CG|H|E> <algorithm arguments> [--bench]
```

| Algorithm | Arguments |
| --- | --- |
| Count Gliders | `CG input.png` |
| Histogram from a file | `H input.csv bin_width [output.csv]` |
| Histogram from a generator | `H seed length bin_width [output.csv]` |
| Emboss | `E input.png [output.png]` |

`--bench` selects 100 repetitions, as defined by `BENCHMARK_RUNS` in `internal/config.h`. The OpenMP/CUDA modes compare results with the serial reference. Use an actual RGB PNG for Emboss; the framework does not include the report's custom RGB benchmark images. The supplied `cg_16_in.png` is intended for the glider example.

## Restored dependencies

| Component | Recovered location |
| --- | --- |
| OpenMP interfaces | `project/src/openmp.h` |
| CUDA interfaces, runtime include and error macros | `project/src/cuda.cuh` |
| Histogram maximum (`255`) and benchmark runs (`100`) | `project/internal/config.h` |
| Serial reference | `project/src/cpu.c` and `cpu.h` |
| CLI, validation and timing harness | `project/internal/` |
| Windows and Linux build definitions | `project/assignment.sln`, `assignment.vcxproj`, `Makefile` |
| PNG support and retained third-party notices | `project/external/stb_image.h`, `stb_image_write.h` |
| Supplied sample | `project/cg_16_in.png` |

The two submitted files use no Thrust or CUB. Histogram input is constrained by the framework to `[0, 255]`. The [results notes](RESULTS_AND_EVIDENCE.md) explain the reference's edge-bin convention.

## Validation completed during recovery

- The ZIP and all original submitted files were compared byte for byte.
- All 25 starter files were verified against the official upstream commit.
- The assembled project differs from the starter only in the two submitted implementation files, with every local quoted include resolvable.
- The original Makefile's Release build plan resolves all source paths in a dry run.
- The unchanged serial `cpu.c` compiles with Apple clang. Its glider classifier matches both submitted mask tables for all 512 possible binary 3×3 windows.

The archive machine is macOS on Apple ARM, without `nvcc` or an OpenMP development runtime. The Windows solution, complete OpenMP program and CUDA kernels have not been built or executed here. No fresh reproduction of the historical 48-case benchmark is claimed. See [verification.json](verification.json) for the recorded scope.
