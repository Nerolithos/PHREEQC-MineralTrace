# v0.3.0 文件清单

修改或刷新既有文件（两份旧验证 Markdown 由实际测试重新生成）：

- `Project.toml`
- `README.md`
- `IMPLEMENTATION.md`
- `src/MineralTrace.jl`
- `src/exploration/Study.jl`
- `src/exploration/Scan.jl`
- `src/reporting/Report.jl`
- `scripts/mineraltrace.jl`
- `test/runtests.jl`
- `data/validation/CAF_C_BENCHMARK.md`
- `data/validation/SYNTHETIC_RECOVERY.md`

新增文件：

- `V030_FILES.md`
- `data/sources/NORDSTROM-2022.json`
- `data/sources/PHREEQC-UPSTREAM-v3.8.6.json`
- `data/sources/PLUMMER-BUSENBERG-1982.json`
- `data/validation/CHEMICAL_QUALITY_AUDIT.md`
- `data/validation/SCIENTIFIC_VALIDATION.md`
- `data/validation/V030_STATUS.md`
- `data/validation/chemical-quality-audit.csv`
- `data/validation/independent-parameter-results.md`
- `data/validation/independent-reference-checks.toml`
- `data/validation/upstream-v3.8.6/ex1.out`
- `data/validation/upstream-v3.8.6/ex1.pqi`
- `data/validation/v020-scan-regression.toml`
- `data/validation/v030-export-audit.txt`
- `data/validation/v030-historical-output.txt`
- `data/validation/v030-test-output.txt`
- `examples/evidence_constraints.toml`
- `examples/evidence_constraints_strict.toml`
- `src/constraints/Constraints.jl`
- `test/constraints.jl`
- `test/validation_v3.jl`

Manifest.toml 和既有科学测试内容未放宽。results/ 中保留原始运行、失败、严格／探索报告及独立复现产物，由既有 .gitignore 排除；未删除旧产物。完整测试与限制见 data/validation/V030_STATUS.md。
