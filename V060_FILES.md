# v0.6.0 文件清单

本清单相对于本轮开始时的干净工作区。全部改动保留在本地，未发布远端标签、Release 或注册包。运行产物位于被忽略的 results/；源码改动与计算归档分开列出。

| 文件 | 用途 |
| --- | --- |
| [IMPLEMENTATION.md](IMPLEMENTATION.md) | 用户入口、科学语义与开发／发布说明 |
| [Project.toml](Project.toml) | 源码版本更新至 0.6.0，标准库依赖保持不变 |
| [README.md](README.md) | 用户入口、科学语义与开发／发布说明 |
| [V060_FILES.md](V060_FILES.md) | 本轮文件清单 |
| [data/sources/CALCITE-EXPERIMENT-SCREENING-V060.json](data/sources/CALCITE-EXPERIMENT-SCREENING-V060.json) | 新筛查实验的来源、支持边界与缺失信息登记 |
| [data/validation/DISCOVERY_ENGINE_COMPARISON.md](data/validation/DISCOVERY_ENGINE_COMPARISON.md) | 验证状态、原始执行日志或导出审计 |
| [data/validation/EXPERIMENTAL_CASE_V060.md](data/validation/EXPERIMENTAL_CASE_V060.md) | 验证状态、原始执行日志或导出审计 |
| [data/validation/PATH_ENGINE_COMPARISON.md](data/validation/PATH_ENGINE_COMPARISON.md) | 完整回归重跑后刷新已有验证记录中的实际运行目录；判据未修改 |
| [data/validation/SYNTHETIC_RECOVERY.md](data/validation/SYNTHETIC_RECOVERY.md) | 完整回归重跑后刷新已有验证记录中的实际运行目录；判据未修改 |
| [data/validation/TITRATION_ENGINE_COMPARISON.md](data/validation/TITRATION_ENGINE_COMPARISON.md) | 完整回归重跑后刷新已有验证记录中的实际运行目录；判据未修改 |
| [data/validation/V060_STATUS.md](data/validation/V060_STATUS.md) | 验证状态、原始执行日志或导出审计 |
| [data/validation/independent-parameter-results.md](data/validation/independent-parameter-results.md) | 完整回归重跑后刷新已有验证记录中的实际运行目录；判据未修改 |
| [data/validation/v060-export-audit.json](data/validation/v060-export-audit.json) | 验证状态、原始执行日志或导出审计 |
| [data/validation/v060-historical-output.txt](data/validation/v060-historical-output.txt) | 验证状态、原始执行日志或导出审计 |
| [data/validation/v060-test-output.txt](data/validation/v060-test-output.txt) | 验证状态、原始执行日志或导出审计 |
| [docs/DISCOVERY.md](docs/DISCOVERY.md) | 用户入口、科学语义与开发／发布说明 |
| [docs/RELEASING.md](docs/RELEASING.md) | 用户入口、科学语义与开发／发布说明 |
| [examples/discovery.toml](examples/discovery.toml) | 完整可执行的合成教学发现配置 |
| [scripts/discover.jl](scripts/discover.jl) | 自动候选机制筛选 CLI |
| [src/MineralTrace.jl](src/MineralTrace.jl) | 加载并导出发现 API |
| [src/discovery/DiscoveryReport.jl](src/discovery/DiscoveryReport.jl) | 自动生成／反应代理筛选／独立报告核心实现 |
| [src/discovery/DiscoverySimulation.jl](src/discovery/DiscoverySimulation.jl) | 自动生成／反应代理筛选／独立报告核心实现 |
| [src/discovery/DiscoveryStudy.jl](src/discovery/DiscoveryStudy.jl) | 自动生成／反应代理筛选／独立报告核心实现 |
| [test/discovery_integration.jl](test/discovery_integration.jl) | 生成独立性、边界与真实 PHREEQC 流程验证 |
| [test/discovery_unit.jl](test/discovery_unit.jl) | 生成独立性、边界与真实 PHREEQC 流程验证 |
| [test/runtests.jl](test/runtests.jl) | 接入新的单元与真实引擎测试 |

主要产物：[最终报告](results/discovery-uhvHwF/report.html)、[独立复现报告](results/discovery-uhvHwF/reproduced/discovery-Aui0VU/report.html)、[执行与科学限制](data/validation/V060_STATUS.md)。

完整实验反应路径验证尚未完成；数值复现和引擎一致性不作为实验验证的替代。
