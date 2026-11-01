# Sprint 2 文件清单

修改既有文件：

- `.gitignore`
- `Project.toml`
- `README.md`
- `src/MineralTrace.jl`
- `src/thermodynamics/PHREEQCAdapter.jl`
- `test/runtests.jl`
- `IMPLEMENTATION.md`

新增文件：

- `data/validation/sprint2-report-audit.txt`

- `SPRINT2_FILES.md`
- `data/validation/CAF_C_BENCHMARK.md`
- `data/validation/EXAMPLE1_INVESTIGATION.md`
- `data/validation/SPRINT2_STATUS.md`
- `data/validation/SYNTHETIC_RECOVERY.md`
- `data/validation/current-engine/console.log`
- `data/validation/current-engine/input.pqi`
- `data/validation/current-engine/output.pqo`
- `data/validation/current-engine/selected.tsv`
- `data/validation/ex1-current-engine.toml`
- `data/validation/ex1-discrepancies.csv`
- `data/validation/sprint2-historical-output.txt`
- `data/validation/sprint2-test-output.txt`
- `examples/fluorite_calcite.toml`
- `examples/known_fluid_template.toml`
- `scripts/investigate_example1.jl`
- `scripts/mineraltrace.jl`
- `src/exploration/Scan.jl`
- `src/exploration/Study.jl`
- `src/reporting/Report.jl`
- `test/cafc.jl`
- `test/exploration.jl`
- `test/exploration_unit.jl`

Manifest.toml 沿用标准库依赖锁定，无外部 Julia 包新增。运行产物在 results/ 下保留，由 .gitignore 排除；未删除第一轮产物。当前版本、API、命令与验证结果见 README.md 和 data/validation/SPRINT2_STATUS.md。
