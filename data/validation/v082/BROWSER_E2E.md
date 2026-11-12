# Browser end-to-end workflow — 2026-11-12

Actual local React production build served on 127.0.0.1:8765, connected to the fixed Julia worker and PHREEQC. Browser automation used the available CUA/Playwright surface; no mocked result data or alternate browser driver.

1. Opened Overview and clicked Create study from transparent example.
2. Confirmed visible synthetic provenance, fluid totals, always-accessible phases and all three grids.
3. Clicked Validate study; Julia returned 210 unique candidates.
4. Clicked Run 210 candidates; observed running state and real progress (153/210), with responsive navigation and cancellation control.
5. Completion opened Candidates with 210 computed entries.
6. Filtered Compatible surrogate: two rows remained, both staged NaOH additions. Inspected candidate `candidate-3cd8f6b0d29b3f6e`: pH 2.1 → 2.1 → 3.278459250135 → 9.81821012172; actual solid transfers displayed, actual chronology UNDETERMINED.
7. Opened Export and downloaded the full actual archive `discovery-o2rz6H.zip`. Verified 8968 files, ZIP CRC integrity, database/source/config/reproduce.jl. Local browser download was about 43.7 MB and took nearly three minutes; large synchronous ZIP packaging is a known usability limit.
8. Reloaded the final production build and inspected Validation: separate engine/experimental/independence sections, three residual series, UNKNOWN calibration status and no pooled score.
9. Checked narrow default layout and 1440×1050 responsive desktop layout, captured screenshots; reset temporary viewport afterward.

Raw local run: `results/workbench/95c45c3d1821447b9052cfe2f092c635/discovery-o2rz6H`. Scientific analysis, not screenshots, is the numerical record. The independent archive reproduction and CLI/API check are in REPRODUCTION_AUDIT.json and API_AUDIT.json.

Screenshots: [desktop](workbench-desktop.png), [narrow](workbench-validation.png).

This is a recorded browser workflow, not a CI-hosted browser test suite. Repeatable backend numerical and lifecycle assertions are implemented in test/workbench_api.py. A browser-runner CI integration, native installer, complete standalone evidence editor and arbitrary archive upload remain unimplemented.
