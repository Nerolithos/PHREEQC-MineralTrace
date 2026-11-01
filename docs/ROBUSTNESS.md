# v0.7.0：阈值稳健性、局部参数敏感性与离散相容区域

本版检查结论对判定规则和有限参数扰动是否稳定。它不把有限网格变成连续反演，也不以稳定分类替代独立实验验证。

## 运行

设置 README 中的 PHREEQC 环境变量，在仓库根目录执行：

```sh
julia --project=. scripts/robustness.jl examples/discovery.toml examples/robustness.toml results
```

它执行原发现计算，使用同一引擎／数据库完成必要的额外单参数计算，输出原 report.html 和 robustness.html。整个示例仍是 SYNTHETIC / SIMULATED，不是真实标本。始终开放所有声明矿物，原来的 210 条候选和原始分类不会被修改。

## 阈值敏感性

`thresholds_mol` 明确给出递增、唯一的检测阈值，必须包含原始阈值且全部高于绝对数值记账容差。阈值是每个操作的固相增量检测规则，不是实验不确定度，也不改变 PHREEQC 反应条件。

程序核对归档配置、数据库、原始输入、selected output 和固相增量，再对同一批真实化学状态重分类。每个阈值记录三类数量、完整检查和具体翻转候选 ID；不重跑化学，不改 pH 或浓度。不支持把改过的旧输入或手工修改增量当成原计算继续分析。

示例的 10⁻⁸、10⁻⁷、10⁻⁶ mol 得到相同的三类结果；10⁻⁴ mol 的较强压力测试将两条相容候选转为无法判断。它说明原结论在声明的近邻阈值上稳定，但对更粗的“显著反应”定义不保持。它不是对所有阈值、数据库或参数范围的稳健性证明。

## 单参数扰动

计划用 `anchor_candidate` 明确选择一条已生成路径，用 `source_id` 说明分析假设。候选 ID 是化学内容身份，配置改变后不可悄悄重新选择一个更相容的锚点。

每个 `[[parameters]]` 提供：

| 字段 | 规则 |
| --- | --- |
| id | 唯一分析编号 |
| parameter | pH、temperature、Ca/F/C(4)/Na/Cl 或 dose |
| units | pH: dimensionless；temperature: degC；总浓度: mol/kgw；dose: mol |
| values | 2–20 个递增唯一样值，必须包含锚点值 |
| operation_index | 初始参数为 0；dose 为环境序列中药剂操作的 1-based 编号，不包含共同初始平衡 |

只有所选参数改变。初始流体的其他总量、环境操作顺序、固相库存、反应方向和可接触性保持固定。改变离子浓度后不自动补偿其他离子，因此电荷诊断可能触发审查；报告将该标记与反应模式变化分开列出。未测量扰动始终是假设，不能冒充分析误差范围。

已有完全相同化学内容的候选直接引用原状态；新扰动用真实 PHREEQC 计算，逐步检查守恒及权限，失败状态保留。累计剂量预算和所有扰动配置在额外计算之前校验；不跳过非法点而隐式收窄范围。

输出包括每个点的分类、定性反应签名、净固相增量、逐相净增量跨度，以及类别／模式是否变化。净固相增量包含共同初始平衡；它不是矿物观测量。`amount_change_threshold_mol` 为报告区分“仅数量变化”与“低于声明变化阈值”的人为准则，必须明确提供。

这些是锚点附近、指定扰动范围内的局部结果。不同参数范围和单位不能未经归一化直接排名为“最重要参数”，相同模式也不证明参数无效。它不提供统计置信区间、全局可辨识性或历史唯一性。

## 二维采样图

`[plane]` 指定两个参数 ID。程序只投影环境序列结构相同、其他全部化学输入都与锚点一致的已计算候选；不同路径或其他参数变化不会混入同一参数面。

示例为初始 pH × 第二步 NaOH 剂量。报告使用离散散点，白色背景不着色，不绘制插值相边界；缺失的笛卡尔组合用灰色 × 标明，点之间的连续区域也全部未计算。全例有 10 个计算点和 2 个缺失组合；不能将缺失点解释为不相容。

所有条件相容点均保留。三类标签针对平衡反应代理，真实形成顺序仍一律 undetermined。

## API、导出与复现

```julia
using MineralTrace
s = load_discovery("examples/discovery.toml")
c = PHREEQCConfig()
r = discover_paths(s, c; root="results")
plan = load_robustness("examples/robustness.toml")
a = analyze_robustness(r, plan, c)
report(r)
report_robustness(r, a)
```

新增 robustness.json、去除运行路径的 robustness-analysis.json、threshold-sensitivity.csv、parameter-sensitivity.csv、sampled-compatibility.svg、robustness.toml 和 reproduce_robustness.jl。全部原始状态、额外扰动计算和来源快照保留在同一个导出目录中。

在导出目录执行：

```sh
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce_robustness.jl
```

使用归档数据库、源码和两个配置。实验终点对照和历史数据库差异归因是另外两条验证轨，见[实验状态](../data/validation/EXPERIMENTAL_CASE_V070.md)和[历史归因](../data/validation/EXAMPLE1_ATTRIBUTION_V070.md)。
