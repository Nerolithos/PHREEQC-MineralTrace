# v0.7.0 文件清单

范围：独立终点定量挑战、阈值与局部参数稳健性、历史基准归因，以及同步的用户文档。未发布远端标签、Release 或注册包。

| 文件 | 用途 |
| --- | --- |
| [IMPLEMENTATION.md](IMPLEMENTATION.md) | 用户价值、操作方法、科学语义与发布边界 |
| [Project.toml](Project.toml) | 源码版本 0.7.0；标准库依赖不变 |
| [README.md](README.md) | 用户价值、操作方法、科学语义与发布边界 |
| [V070_FILES.md](V070_FILES.md) | 本轮文件清单 |
| [data/sources/PHREEQC-HISTORICAL-V070.json](data/sources/PHREEQC-HISTORICAL-V070.json) | 原始来源、DOI、许可、快照与校验摘要 |
| [data/sources/REFLECT-D23-2023.json](data/sources/REFLECT-D23-2023.json) | 原始来源、DOI、许可、快照与校验摘要 |
| [data/sources/REFLECT-D23-2023.pdf](data/sources/REFLECT-D23-2023.pdf) | 原始来源、DOI、许可、快照与校验摘要 |
| [data/validation/DISCOVERY_ENGINE_COMPARISON.md](data/validation/DISCOVERY_ENGINE_COMPARISON.md) | 完整回归重跑刷新运行目录；判据与历史值未修改 |
| [data/validation/EXAMPLE1_ATTRIBUTION_V070.json](data/validation/EXAMPLE1_ATTRIBUTION_V070.json) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/EXAMPLE1_ATTRIBUTION_V070.md](data/validation/EXAMPLE1_ATTRIBUTION_V070.md) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/EXAMPLE1_INVESTIGATION.md](data/validation/EXAMPLE1_INVESTIGATION.md) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/EXPERIMENTAL_CASE_V070.md](data/validation/EXPERIMENTAL_CASE_V070.md) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/PATH_ENGINE_COMPARISON.md](data/validation/PATH_ENGINE_COMPARISON.md) | 完整回归重跑刷新运行目录；判据与历史值未修改 |
| [data/validation/SYNTHETIC_RECOVERY.md](data/validation/SYNTHETIC_RECOVERY.md) | 完整回归重跑刷新运行目录；判据与历史值未修改 |
| [data/validation/TITRATION_ENGINE_COMPARISON.md](data/validation/TITRATION_ENGINE_COMPARISON.md) | 完整回归重跑刷新运行目录；判据与历史值未修改 |
| [data/validation/V070_STATUS.md](data/validation/V070_STATUS.md) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/historical-2012/commits.json](data/validation/historical-2012/commits.json) | 官方历史数据库原始字节与提交元数据；不替代生产数据库 |
| [data/validation/historical-2012/phreeqc.dat](data/validation/historical-2012/phreeqc.dat) | 官方历史数据库原始字节与提交元数据；不替代生产数据库 |
| [data/validation/historical-2013/commits.json](data/validation/historical-2013/commits.json) | 官方历史数据库原始字节与提交元数据；不替代生产数据库 |
| [data/validation/historical-2013/phreeqc.dat](data/validation/historical-2013/phreeqc.dat) | 官方历史数据库原始字节与提交元数据；不替代生产数据库 |
| [data/validation/independent-parameter-results.md](data/validation/independent-parameter-results.md) | 完整回归重跑刷新运行目录；判据与历史值未修改 |
| [data/validation/reflect-2023/PROTOCOL.md](data/validation/reflect-2023/PROTOCOL.md) | 计算前冻结的实验点与预定协议 |
| [data/validation/reflect-2023/observations.csv](data/validation/reflect-2023/observations.csv) | 计算前冻结的实验点与预定协议 |
| [data/validation/v070-attribution-output.txt](data/validation/v070-attribution-output.txt) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/v070-export-audit.json](data/validation/v070-export-audit.json) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/v070-historical-output.txt](data/validation/v070-historical-output.txt) | 归因、科学结果、测试日志或独立导出审计 |
| [data/validation/v070-test-output.txt](data/validation/v070-test-output.txt) | 归因、科学结果、测试日志或独立导出审计 |
| [docs/CALCITE_ENDPOINT.md](docs/CALCITE_ENDPOINT.md) | 用户价值、操作方法、科学语义与发布边界 |
| [docs/RELEASING.md](docs/RELEASING.md) | 用户价值、操作方法、科学语义与发布边界 |
| [docs/ROBUSTNESS.md](docs/ROBUSTNESS.md) | 用户价值、操作方法、科学语义与发布边界 |
| [examples/robustness.toml](examples/robustness.toml) | 显式锚点、扰动和检测阈值教学计划 |
| [scripts/attribute_example1.py](scripts/attribute_example1.py) | 可执行研究／验证／只读来源审计入口 |
| [scripts/check_reflect_digitization.py](scripts/check_reflect_digitization.py) | 可执行研究／验证／只读来源审计入口 |
| [scripts/robustness.jl](scripts/robustness.jl) | 可执行研究／验证／只读来源审计入口 |
| [scripts/validate_calcite_endpoint.jl](scripts/validate_calcite_endpoint.jl) | 可执行研究／验证／只读来源审计入口 |
| [src/MineralTrace.jl](src/MineralTrace.jl) | 加载并导出本版研究／验证接口 |
| [src/discovery/DiscoveryReport.jl](src/discovery/DiscoveryReport.jl) | 报告关联本版独立实验状态，保留旧记录回退 |
| [src/robustness/Robustness.jl](src/robustness/Robustness.jl) | 原状态阈值复评、单参数真实反应与离散采样报告 |
| [src/robustness/RobustnessReport.jl](src/robustness/RobustnessReport.jl) | 原状态阈值复评、单参数真实反应与离散采样报告 |
| [src/validation/CalciteEndpoint.jl](src/validation/CalciteEndpoint.jl) | 受控 CO₂ 纯水方解石终点；显式未验证状态与原子／电荷记账 |
| [test/credibility_integration.jl](test/credibility_integration.jl) | 科学边界、原状态完整性、真实引擎与历史匹配验证 |
| [test/credibility_unit.jl](test/credibility_unit.jl) | 科学边界、原状态完整性、真实引擎与历史匹配验证 |
| [test/runtests.jl](test/runtests.jl) | 新增检查入口，保留既有回归 |

主要产物：[独立终点报告](results/calcite-validation-n1l1wm/report.html)、[稳健性报告](results/discovery-qktTgC/robustness.html)、[状态与限制](data/validation/V070_STATUS.md)。

实验对照暴露系统偏差；保留两个质量基准和缺失元数据，不声称模型或实际矿物形成顺序获验证。
