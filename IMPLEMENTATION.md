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


v0.7.0 科学可信度工作见[稳健性说明](docs/ROBUSTNESS.md)、[独立终点检验](docs/CALCITE_ENDPOINT.md)、[历史差异归因](data/validation/EXAMPLE1_ATTRIBUTION_V070.md)、[执行记录](data/validation/V070_STATUS.md)及[文件清单](V070_FILES.md)。独立终点出现偏差，未被标为模型验证通过。

v0.7.1：五点冻结观测的受控偏差归因、原文计量审计、模型适用性证据登记及复现报告见[归因报告](data/validation/v071/REPORT.md)。未新增机制；未将 Pitzer 改善解释为已验证模型。

v0.8.0：可执行的 TOML 模型档案／证据登记、基于物种／温压／I／边界／数据库／观测量的保守适用性匹配、候选独立注释、REFLECT 逐字段原文审计及描述误差、官方 Examples 6/7/22 固定版本基准。见[科学验证说明](docs/SCIENTIFIC_VALIDATION.md)。没有实验支持的严格路径档案，偏差原因仍未解决；原科学结果不重定标。

v0.8.1：冻结第二组独立来源的 25 °C 纯水方解石实验，保持原模型和 REFLECT 不变；五点预测偏低 1.246%–10.404%，与 REFLECT 不同域的正向偏差不同。公开原文不确定度、源记录与数据库参数历史分别审查，严格校准留出独立性仍 UNKNOWN。见[实验工作流](docs/INDEPENDENT_EXPERIMENT.md)与[比较报告](data/validation/v081/REPORT.md)。
