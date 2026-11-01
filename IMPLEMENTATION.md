# 首轮交付文件清单

初始目录为空，未覆盖已有文件，也未初始化 Git 仓库。以下文件均为本轮新建。

- `.gitignore`
- `IMPLEMENTATION.md`
- `LICENSE`
- `Manifest.toml`
- `Project.toml`
- `README.md`
- `data/sources/USGS-EX1-TABLE11.json`
- `data/sources/USGS-EX2-TABLE13.json`
- `data/sources/USGS-PHREEQC-3.8.6-17100.json`
- `data/sources/input-files.json`
- `data/validation/DATABASE_REVIEW.md`
- `data/validation/STATUS.md`
- `data/validation/ex1-reference.toml`
- `data/validation/legacy-benchmark-output.txt`
- `data/validation/pkg-test-output.txt`
- `data/validation/test-output.txt`
- `data/validation/usgs-ex1.pqi`
- `data/validation/usgs-ex2.pqi`
- `examples/forward.jl`
- `examples/paragenesis.jl`
- `scripts/benchmark.jl`
- `scripts/check_environment.jl`
- `src/MineralTrace.jl`
- `src/models/FormationEvent.jl`
- `src/paragenesis/EvidenceGraph.jl`
- `src/thermodynamics/PHREEQCAdapter.jl`
- `test/integration.jl`
- `test/runtests.jl`

`results/run-*/` 为真实运行产生的保留归档，包含原始输入输出、数据库快照、进程日志和清单。它们由 .gitignore 排除，不会静默删除。验证过程中的成功运行、PHREEQC 错误运行和未知相拒绝运行均保留；以各自 manifest.toml 为准。

功能、来源与版本、测试结果、失败基准、未验证事项和下一步工作见 [README](README.md)、[验证记录](data/validation/STATUS.md) 和 [数据库初查](data/validation/DATABASE_REVIEW.md)。

第二轮交付见 [Sprint 2 文件清单](SPRINT2_FILES.md) 和 [验证汇总](data/validation/SPRINT2_STATUS.md)。

v0.3.0 交付见 [文件清单](V030_FILES.md) 和 [执行记录](data/validation/V030_STATUS.md)。

v0.4.0 交付见 [文件清单](V040_FILES.md) 和 [执行记录](data/validation/V040_STATUS.md)。

v0.5.0 交付见 [文件清单](V050_FILES.md) 和 [执行记录](data/validation/V050_STATUS.md)。


v0.6.0 自动候选机制筛选见 [使用说明](docs/DISCOVERY.md)、[文件清单](V060_FILES.md)与[执行记录](data/validation/V060_STATUS.md)。显著版本更新必须同步维护 README 中的用户价值、操作方法与科学边界。
