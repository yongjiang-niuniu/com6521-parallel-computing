# Attribution and recovered materials

## Student submission

The student work preserved here is the official COM6521/COM4521 submission associated with Yongjiang Liu's Blackboard attempt: `openmp.c`, `cuda.cu` and `comcuda_report.pdf`. The report records the author's implementation choices, evaluation workflow and AI-assistance statement. All three files are unchanged in [submitted/](../submitted/).

## Course framework

The [official assignment brief](../archive/com4521com6521_assignment2526_v2.pdf), page 5, requires these two implementation files and a report in one ZIP; it expressly says no other project files need to be handed in. The original submission's omission of the framework is therefore consistent with the required deliverables.

The v7 starting-code archive was recovered from the same Blackboard assignment's instructions. Its 25 files match the official [RSE-Sheffield/COMCUDA_assignment_fe221142](https://github.com/RSE-Sheffield/COMCUDA_assignment_fe221142) repository at commit [`fb649d39e8637e552dbe56a096ece1f34b092d36`](https://github.com/RSE-Sheffield/COMCUDA_assignment_fe221142/commit/fb649d39e8637e552dbe56a096ece1f34b092d36), dated 29 April 2026. The ZIP comment identifies that commit, and every file's Git blob hash was independently checked against it.

The recovered [project/](../project/) changes only the two implementation files from this starter. The serial reference, harness, build files and support headers are course-provided material; they are not presented as original student code. The upstream Git history has not been imported. The [framework provenance](../archive/framework_provenance.json) records the source archives and exact assembly changes.

At recovery, upstream `master` pointed to `c62a0e2932d9d5ca5f28977b751488c54db97eff`, which differs from the official v7 ZIP only in `nsys.bat`. The preserved tree uses the downloaded v7 snapshot, not a silently substituted newer script.

No top-level license file was found in the recovered framework, and GitHub returned no repository license. The owner has authorized publication of this coursework archive. It does not add a license on behalf of the course authors; earlier private-publication records remain a dated record of recovery. Both bundled `stb_image.h` and `stb_image_write.h` retain their original MIT/public-domain alternatives and attribution.

## Brief and source consistency

The brief's algorithm sections, supplied headers, serial implementation and executable agree on Count Gliders, Histogram and Emboss. One paragraph on page 5 contains stale wording about “two algorithms” and `openmp_chromaticaberration`; it conflicts with those concrete interfaces. The archive describes the three implemented algorithms and preserves the brief without editing it.
