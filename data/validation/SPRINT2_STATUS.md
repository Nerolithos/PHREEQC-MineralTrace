# Sprint 2 — Formation Constraint Explorer, 2026-11-01

版本 0.2.0。已交付配置驱动的基础探索流程，不声称已经完成天然矿床研究模式的科学验证。

## 验收与实际运行

- 无需编辑 Julia：`scripts/mineraltrace.jl STUDY.toml OUTPUT_DIRECTORY`。
- KnownFluid／HypothesisExplorer、1D／2D、温度／pH／浓度扫描，单位与边界校验，明确同阶段假设和逐矿物容差。
- 每点真实 PHREEQC；失败无 SI 默认值，分类独立于化学告警。
- 独立 HTML、SI SVG、SI=0 插值线、联合分类、失败标记、CSV／JSON、完整配置与原始归档。
- 每个 study 保存数据库快照、源码、来源记录、验证摘要和复现脚本；每点保留输入、输出和 manifest。
- 原有证据 DAG 独立且仍通过测试，没有从扫描生成时间约束。

演示命令：

```sh
julia --project=. scripts/mineraltrace.jl --check examples/fluorite_calcite.toml
julia --project=. scripts/mineraltrace.jl examples/fluorite_calcite.toml results
```

本轮最终演示归档：`results/study-RdSUoz/report.html`。42 点真实计算；5 个 SI 相容、37 个不相容、0 个失败；41 点有化学告警。SI 相容采样点的外包范围为温度 25–65 °C、pH 7.5–8.0，**不是连续可行域、置信区间或真实形成环境**。必须逐点审查电荷误差；不能把所有相容点都当成有效天然流体。

演示浓度是明确标记的合成名义离子配方，不是实测数据；指定 pH 后仍可能不平衡。没有按天然案例参考答案调参。敏感性按声明范围归一化，本例 pH 响应大于温度；不能推广为普遍结论。

## 执行测试

实际运行 Julia 1.10.10、macOS ARM64、PHREEQC 3.8.6-17100。沿用该官方发行包的原始 phreeqc.dat，SHA-256 `59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`。

```sh
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

**204/204 通过，退出码 0**；详见 [完整测试输出](sprint2-test-output.txt)。

| 测试集 | 通过项数 |
| --- | ---: |
| 既有 DAG | 13 |
| 既有输入与依赖错误 | 8 |
| SELECTED_OUTPUT 完整性 | 8 |
| 新配置、单位、边界与 SI 分类 | 19 |
| 真实引擎执行与错误处理 | 10 |
| 官方 Example 2 对照 | 4 |
| 当前锁定引擎回归 | 5 |
| Ca–F–C 专项一致性 | 59 |
| 网格映射、报告、离网格恢复、多解及缺相 | 66 |
| 进程退出／超时归档 | 12 |

专项验证使用引擎输出的活度／log K 检查 SI 定义，并以独立元素计数检查沉淀和溶解反应的水相加固相总量。测试通过不等于热力学数据已获实验验证。合成恢复匹配的是非网格点的正向 SI 特征，不是天然观测或唯一反演；见 [专项结果](CAF_C_BENCHMARK.md) 和 [合成恢复记录](SYNTHETIC_RECOVERY.md)。

## Example 1 双轨验证

[差异调查](EXAMPLE1_INVESTIGATION.md) 与 [结构化差值 CSV](ex1-discrepancies.csv) 已保存。直接 CLI 与适配器的高精度 SI 一致；历史三项数值差异仍超过原始 0.01 容差，未扩大容差。历史表格对应的精确旧引擎／数据库未取得，尚未确认具体因果参数。

`julia --project=. scripts/benchmark.jl` 在本轮重新运行，保留 **3 项失败，退出码 1**；见 [历史对照日志](sprint2-historical-output.txt)。此失败不被常规通过数掩盖。当前引擎回归基线独立捕获自直接 CLI，原始输入、输出、SELECTED_OUTPUT、控制台记录位于 `current-engine/`；它只能检验稳定性和适配器一致性。

## 报告与复现检查

- SVG 实际渲染为 PNG 并目视检查：SI 色阶、零线、坐标、联合区域及图例。
- 独立检查 JSON、CSV 和 SVG XML；每点归档、数据库摘要、源码摘要均核对。
- 在导出目录运行 `PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl`，使用归档数据库、配置及源码独立重算；逐点比较 SI 和分类。
- HTML 无脚本依赖或外部资源请求。移走伴随文件仍可阅读内嵌图表和结果；原始日志检查与重算需保留整个文件夹。

## 尚未完成与下一步

25–80 °C 是显式选择的探索范围，不是已认证温区；CaF+ 在锁定数据库中被注释。物种完整性、离子强度与高温准确性仍需独立审查。其他数据库仅允许作为明确标记的未审查输入，没有实施跨数据库实验验证或拼接常数。

未进行天然矿床独立验证，也未实现概率反演、信息增益、自动成矿历史或复杂界面。下一里程碑优先获得版本匹配参考与 Ca–F–C 实验对照，增强流体化学质量约束及容差敏感性分析，再扩展研究模式。

本机工具仍暂装 `/tmp`，并非系统安装。`Pkg.test()` 的全新注册表网络限制记录属于第一轮；本轮直接测试入口不依赖下载注册表。
