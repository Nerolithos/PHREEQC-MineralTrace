# v0.4.0 文件清单

修改或由实际测试刷新既有文件：

- `Project.toml`
- `README.md`
- `IMPLEMENTATION.md`
- `src/MineralTrace.jl`
- `src/exploration/Study.jl`
- `src/exploration/Scan.jl`
- `src/reporting/Report.jl`
- `test/runtests.jl`
- `data/validation/CAF_C_BENCHMARK.md`
- `data/validation/SYNTHETIC_RECOVERY.md`
- `data/validation/independent-parameter-results.md`

新增文件：

- `V040_FILES.md`
- `data/sources/PLUMMER-BUSENBERG-1999-OFR99247.json`
- `data/sources/USGS-OFR99-247.pdf`
- `data/validation/CHARGE_BALANCE_SEMANTICS.md`
- `data/validation/EXPERIMENTAL_CASE_V040.md`
- `data/validation/TITRATION_ENGINE_COMPARISON.md`
- `data/validation/V040_STATUS.md`
- `data/validation/experimental-case-v040.json`
- `data/validation/v040-export-audit.txt`
- `data/validation/v040-historical-output.txt`
- `data/validation/v040-test-output.txt`
- `examples/acid_titration.toml`
- `examples/base_titration.toml`
- `scripts/titrate.jl`
- `src/processes/ProcessReport.jl`
- `src/processes/Titration.jl`
- `src/thermodynamics/ChargeDiagnostics.jl`
- `test/process_integration.jl`
- `test/process_unit.jl`

Manifest.toml 沿用现有标准库依赖；PDF 工具仅用于开发时阅读原始实验资料，不是 Julia 包运行依赖。results/ 保留真实运行、失败、直接 CLI 对照和独立复现，由原有 .gitignore 排除。没有删除旧档案或放宽历史科学测试。
