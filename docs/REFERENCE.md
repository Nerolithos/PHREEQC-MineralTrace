# 功能与科学边界详细参考

本页保留截至 v0.5.0 的扫描、证据约束、滴定与路径接口详细说明，按功能演进组织。首次使用请从[项目首页](../README.md)开始；以下命令均在仓库根目录执行。

# MineralTrace — Mineral Formation Constraint Explorer

v0.5.0 新增有限矿物反应路径比较，见 [两条候选路径示例](../examples/reactive_paths.toml)；v0.4.0 新增真实酸碱滴定与过程报告，见下方 v0.4.0 章节；v0.3.0 新增证据约束、严格／探索评估、化学质量与模型适用性门槛、逐项排除原因和约束贡献；优先使用 [证据配置示例](../examples/evidence_constraints.toml) 或 [严格模式配置](../examples/evidence_constraints_strict.toml)。详见下方 v0.3.0 章节。

矿物形成环境约束探索工具：**编辑 TOML → 真实 PHREEQC 参数扫描 → 查看 SI 共相容点 → 导出独立 HTML 报告**。不需要编写 Julia，也不需要 Web 服务器。

当前版本 0.5.0（保留扫描、证据约束及滴定接口），面向 Fluorite–Calcite 与简化 Ca–F–C–O–H／Na／Cl 水溶液。它回答“在指定流体、范围和同阶段平衡假设下，哪些采样条件符合声明的 SI 容差”，不能从矿物名称证明形成温度、沉淀行为或生成历史。

## 十分钟开始一次探索

需要 Julia 1.10+ 和官方 PHREEQC 3 CLI。设置实际路径后，在项目根目录运行：

```sh
export PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc
export PHREEQC_DATABASE=/absolute/path/to/phreeqc.dat
julia --project=. scripts/mineraltrace.jl --check examples/fluorite_calcite.toml
julia --project=. scripts/mineraltrace.jl examples/fluorite_calcite.toml results
```

终端会打印 `results/study-…/report.html` 的完整路径。用浏览器打开即可；整个 HTML 内嵌所有 SVG、参数和结果，不需要联网。保留完整 study 文件夹，才能检查原始 PHREEQC 运行或复现。

示例为 **SYNTHETIC / SIMULATED**，不是实测流体。复制 `examples/fluorite_calcite.toml`，编辑自己的参数文件即可，无需修改 Julia 源码。该示例展示 42 个温度–pH 点；部分点有电荷不平衡告警，不能直接当作天然流体模型。

每份报告包括：

- 每个矿物的 SI 热力图和 SI=0 插值线、一维扫描时的 SI 曲线。
- 采样点的联合 SI 相容／不相容／失败分类及告警标记。
- 相容采样范围、基于相邻点差分的范围归一化敏感性和多解性说明。
- 完整固定参数、扫描参数、单位、用户容差、来源及假设。
- 引擎 banner、数据库与输入摘要、失败原因和每点原始归档链接。
- CSV、JSON、TOML、独立 SVG、数据库快照、核心源码与复现脚本。

## 输入模式与参数

`HypothesisExplorer`：流体来源必须为 `Assumption`。结果明确标记 **Conditional on assumed fluid composition ranges**。

`KnownFluid`：用户提供实测或明确实验条件、来源和 `Observation` 标签。软件保留用户声明，不替用户认证测量；扫描范围和同阶段平衡仍是额外假设。`examples/known_fluid_template.toml` 故意不填测量值，填完整前不能运行。

所有配置项必须显式给出，未知键会被拒绝：

| 配置 | 规则 |
| --- | --- |
| `minerals` | Fluorite、Calcite 中选择一个或两个 |
| `assumption` | 必须声明 `same_stage_equilibrium` |
| `fluid.totals` | Ca、F、C(4)、Na、Cl 均显式填写，包括排除组分时的零值；单位只接受 mol/kgw |
| `fluid.origin/label/source` | 事实／假设分类、输入标签、可核查来源或明确的合成来源说明 |
| `fixed` | temperature、pH、pe、pressure_atm、water_kg 全部填写 |
| `axes` | 一或两个轴；参数为 temperature、pH 或上述总浓度；至少两个严格递增值 |
| 轴单位 | temperature 为 degC，pH 为 dimensionless，总浓度为 mol/kgw |
| `tolerances` | 每个所选矿物分别声明正 SI 容差，严格判据为 `abs(SI) < tolerance` |

当前探索边界为 25–80 °C、pH 0–14、各组分 0–0.1 mol/kgw、固定 1 atm 和 1 kg 初始水。它们是软件范围限制，**不是数据库适用性认证**。25 °C 以外必须显式设置 `allow_unvalidated_temperature = true`。便捷 `FluidState` API 也保留此显式选择。

未列入的其他元素在此简化模型中被排除，不能把不完整天然分析表当成完整流体。无元素浓度、同阶段证据或范围时，软件不会自动补出成矿环境。

扫描轴的值只替代对应固定基值；其余值保留。每个采样点都是独立的初始物种分布计算，未加入矿物反应、动力学或多阶段演化。

## 结果应如何解释

“SI 相容”仅表示给定化学模型下同时满足用户容差；不是自然界统一的平衡判据，也不是已确认沉淀。“不相容”只排除当前输入与容差下的采样点，不能排除其他流体或未采样条件。

电荷误差绝对值超过 0.1% 会产生诊断告警，不自动调节任何离子。报告保留 SI 分类和化学质量告警两个维度；带告警的相容点需先审查化学条件。0.1% 不是天然样品的通用质量标准。

失败点没有 SI 值，显示为灰色／叉号；绝不填零或归入不相容。CLI 在任一点失败时仍写出报告，并以退出码 1 提示；配置或依赖错误则明确退出，不调用假引擎。

热力图色块代表采样点，不能当成连续可行域。SI=0 线在相邻成功样点之间做线性插值，不跨越失败点；有四个交点的歧义鞍点单元不连线。没有零点跨越时不会画出零线。一维图在失败点处断线。

多个相容点会明确报告无法唯一约束；只有一个相容点也不能证明网格之间或范围以外无解。敏感性依赖声明范围，仅为 SI 响应排序，不是概率、信息增益或完整统计可辨识性。

## 安装依赖

从 [Julia 官网](https://julialang.org/downloads/) 安装 Julia，从 [USGS 官方发布页](https://www.usgs.gov/software/phreeqc-version-3) 获取引擎与配套数据库。例如本项目实际测试版本：

```sh
curl -fLO https://water.usgs.gov/water-resources/software/PHREEQC/phreeqc-3.8.6-17100.tar.gz
tar -xzf phreeqc-3.8.6-17100.tar.gz
cmake -S phreeqc-3.8.6-17100 -B phreeqc-build -DCMAKE_BUILD_TYPE=Release
cmake --build phreeqc-build -j 4
export PHREEQC_EXECUTABLE="$(pwd)/phreeqc-build/phreeqc"
export PHREEQC_DATABASE="$(pwd)/phreeqc-3.8.6-17100/database/phreeqc.dat"
```

项目仅依赖 Julia 标准库。已附 `Manifest.toml`，可直接运行上述命令；联网环境也可执行 `julia --project=. -e 'using Pkg; Pkg.instantiate()'`。受限网络中全新 depot 的 `Pkg.test()` 可能在获取默认注册表时失败，可使用下列直接测试入口。

本机实际测试 Julia 1.10.10／macOS ARM64、PHREEQC 3.8.6-17100。此前工具暂装在 `/tmp`，未修改系统安装；临时目录被清理后需重装。

## API 与复现

```julia
using MineralTrace
study = load_study("examples/fluorite_calcite.toml") # 或 MineralStudy(spec_dictionary)
result = scan(study, PHREEQCConfig(); root="results")
path = report(result)
```

`ScanResult.samples` 按 x 轴最快排列，索引为 `(iy-1)*nx+ix`。每点保存坐标、SI、分类、警告、错误和原始目录。`compatibility` 提供 SI 判据；`signature_matches` 用于单独的正向 SI 特征匹配测试，不把任意 SI 目标当成共平衡证据。

进入导出的 study 文件夹后运行：

```sh
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl
```

使用归档数据库、配置及源码复现；应核对可执行文件摘要和引擎版本。不同机器构建的二进制摘要可能不同，不能冒称完全相同的计算环境。

既有 `FormationEvent`、`Evidence`、`EvidenceGraph`、`analyze` 和 `topological_order` 保持独立工作。事件 ID 区分重复矿物阶段；循环抛出携带冲突证据的 `CycleConflict`；不能从扫描结果生成时间边。`run_phreeqc` 仍是可信专家输入接口，不是任意 PHREEQC 文件的安全沙箱。

## 验证状态

```sh
julia --project=. test/runtests.jl
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
julia --project=. scripts/benchmark.jl
```

前两条分别运行基础测试和真实引擎集成测试。最后一条保留 **已知失败** 的历史 Example 1 对照，预期退出码 1；不能用它的失败掩盖或替代其他测试。

- [Example 1 差异调查](../data/validation/EXAMPLE1_INVESTIGATION.md)：历史值、实际值、差值／相对差、输入与列映射检查，以及直接 CLI 对照。
- [Ca–F–C 专项测试](../data/validation/CAF_C_BENCHMARK.md)：浓度、pH、温度、SI 定义、电荷诊断及沉淀／溶解元素守恒。
- [离网格合成测试](../data/validation/SYNTHETIC_RECOVERY.md)：仅证明正向特征匹配与包围关系，不证明真实矿床预测能力。
- [本轮验证汇总](../data/validation/SPRINT2_STATUS.md)、[数据库初查](../data/validation/DATABASE_REVIEW.md)。

历史 Example 1 三项差异仍未完全解释；当前引擎回归只能证明稳定性和适配器一致性。官方 Example 2 的 25 °C SI 对照通过，不能替代整个 Ca–F–C 体系验证。当前数据库 CaF+ 被注释，物种完整性、活度模型和全部温区尚未完成独立验证。不同数据库须独立审查，不能拼接参数。

没有天然矿床独立验证，没有贝叶斯反演、信息增益、AI 成矿故事或自动形成顺序预测。下一阶段应优先完成版本匹配的参考验证、专门的 Ca–F–C 实验对照及流体化学质量约束，再考虑更复杂界面。

## 官方资料

[PHREEQC 3 手册](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3.htm) · [SELECTED_OUTPUT](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-45.htm) · [Example 1](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-63.htm) · [Example 2](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-64.htm)

MIT 许可证见 LICENSE。USGS 数据与示例保留原始来源，来源记录位于 `data/sources/`。

## v0.3.0：证据、化学质量与最终可行域

本节更新前文 v0.2.0 的 SI 扫描解释；原扫描输入、SI 和告警数值保持兼容，不能把旧的 `status` 字段当成最终纳入状态。

```sh
julia --project=. scripts/mineraltrace.jl --check examples/evidence_constraints.toml
julia --project=. scripts/mineraltrace.jl examples/evidence_constraints.toml results
```

`examples/evidence_constraints.toml` 展示全部六类约束与明确阶段分配。它的“观测”值也是 **SYNTHETIC / SIMULATED** 教学数据，不是天然样品测量。用户可直接替换为自己的来源与约束，无需修改 Julia。

```toml
stage_id = "STAGE-I"
[evaluation]
mode = "strict" # 或 exploratory
max_charge_error_percent = 0.1

[[constraints]]
id = "temperature-window"
parameter = "temperature"
type = "interval"
units = "degC"
classification = "Observation"
# source_id = "实际来源编号" # 缺失时省略，不虚构
stage_id = "STAGE-I"
lower = 30.0
upper = 40.0
```

该片段需放入完整 study 配置；不是可独立运行的流体模型。约束的分类由用户声明，软件不替用户认证原始证据。

| type | parameter / units | 附加字段 |
| --- | --- | --- |
| interval | temperature / degC，pH / dimensionless，或组分 / mol/kgw | lower、upper，闭区间 |
| measurement | Ca、F、C(4)、Na、Cl / mol/kgw | value、tolerance，绝对浓度误差，包含边界 |
| saturation | Fluorite、Calcite / SI | value、正 tolerance，严格 `abs(SI-value)<tolerance`；必须是 Assumption；阶段不明时未验证 |
| quality | charge_error / percent | upper，绝对电荷误差上限，包含边界 |
| stage | Fluorite、Calcite / stage_id | stage_id，与 study 阶段比较；不生成时间顺序 |

每条约束必须有唯一 id、parameter、type、units、classification；source_id 和适用时的 stage_id 保留原始缺失状态。未知或不适用字段被拒绝。观测区间可在扫描范围之外，结果为空不等于配置无效；物理单位／绝对温度等基础边界仍校验。更严格的 quality 约束与 `[evaluation]` 阈值共同生效，不会覆盖或放宽基本要求。

每点新增 `evaluation`，分别记录：

- computational_status 与 failure_kind：计算成功、缺相、已识别数值失败或其他引擎／输出失败。
- chemical_quality_status：按声明电荷阈值 pass／fail／unverified。
- model_applicability_status：verified／invalid／unverified。当前没有经完整独立验证的模型配置，保持 unverified；缺相为 invalid。
- observation_status：仅观测类约束的状态；没有观测时的 pass 是空约束集的逻辑结果，不是正面证据。
- final_status：included／included_conditional／excluded／unverified，附逐项理由。

**严格模式**不纳入未验证模型、不可求值证据或缺失来源；当前严格最终可行域为零，不能解释成地质环境不存在。**探索模式**可保留明确标记的条件性候选，但仍排除电荷阈值失败、SI 不相容和硬证据冲突；未能求值的约束也不能通过。

旧配置未指定 evaluation 时，显式披露采用 legacy exploratory／0.1% 策略。PHREEQC 输入从不自动添加 `charge` 调整项，未实现电中性修正场景，也不改变测量浓度。原有 0.1% 适配器告警始终保留，用户另设评估阈值不会擦除原始告警。

报告分别输出原始 SI、化学、模型、观测、最终纳入、告警、排除与计算状态；`chemical.svg`、`model.svg`、`observations.svg`、`final.svg`、`warnings.svg`、`exclusions.svg`、`computational.svg` 均独立于 `joint.svg`。观测区域是原始 SI ∩ 化学通过 ∩ 观测通过；最终区域还包括所有假设约束和模式策略。

约束贡献保留 SI／化学候选轨和最终策略轨：基线、按声明顺序逐条过滤、每次删除一条的 leave-one-out、网格相对冗余及冲突。严格模式最终基线为零时，不能把候选轨的减少冒称最终可行域的减少。空基线或未知证据不构成已证实冲突。离散格点的四邻域连通分量也不等于已证明的连续地质区域。

新增 `constraints.csv`、`constraint-evaluations.csv`、`constraint-contribution.csv`；JSON 与 CSV 均保留独立状态与原因。`analysis.json` 是去除运行路径／时间戳的确定性科学载荷；`results.json` 另保留完整运行溯源。报告仍可离线打开，复现脚本仍使用归档源代码和数据库。

新 API：`EvidenceConstraint`、`evaluate_constraints`、`constraint_contribution`、`charge_equivalents`。后者接受**水溶液物种**的 molality 和整数电荷，不把总无机碳当成单一带电离子，也不是另一套活度模型。

- [逐点化学质量审计](../data/validation/CHEMICAL_QUALITY_AUDIT.md)
- [科学验证状态](../data/validation/SCIENTIFIC_VALIDATION.md)
- [v0.3.0 执行记录](../data/validation/V030_STATUS.md)

已取得版本匹配的官方 Example 1 输出并通过对照；历史手册三项差异仍保留。两个独立文献记录的 log K 数值筛查也通过，但完整独立水溶液案例、物种完整性、全部温区和真实矿床验证仍未完成。严格模式不会因这些局部检查而被自动标为模型已验证。

约束复评使用 scan 产生的样点，校验实际 PHREEQC 输入 SHA-256；改变流体／输入后必须重算，显式请求不同数据库也会被拒绝。始终执行真实计算，不实现模糊匹配缓存。

## v0.4.0：真实酸碱反应过程

```sh
julia --project=. scripts/titrate.jl examples/acid_titration.toml results
julia --project=. scripts/titrate.jl examples/base_titration.toml results
```

同一个水溶液经过 PHREEQC `REACTION`／`INCREMENTAL_REACTIONS true` 推进；只指定初始 pH，各步 pH 由反应求解。支持 HCl 和 NaOH 的中性化学式添加，`amounts_mol` 是每一步的**增量摩尔数**，不是累计数、摩尔浓度或滴定体积。选择监测 Calcite／Fluorite；它们不是自动反应的固相。

必须明确选择 `addition_model = "formula_addition_no_carrier_water"`。这是无载体水添加的理想化学式转移；不将未知滴定液体积悄悄视作零稀释。不支持含载体水的体积滴定、气体交换、矿物溶解／沉淀、反应速率或时间演化。实际实验若需要这些边界，不能直接套用本模型。

初始 Ca、F、C(4)、Na、Cl 都需显式提供，单位 mol/kgw，同时给出初始水质量、pH、pe、温度、来源、Observation／Assumption 分类和 `charge_context`。纯 H+ 添加、负剂量、未知药剂、含糊单位和未说明的载体水模型会被拒绝。25 °C 外仍需明确接受未验证温区；1 atm 压力固定。

API：

```julia
p = load_process("examples/acid_titration.toml") # 或 AcidBaseTitration(spec)
r = simulate(p, PHREEQCConfig(); root="results")
path = report(r)
```

输出包含独立 HTML、6 张实际计算 SVG、`steps.csv`（pH／SI／总量／溶解物种）、`balances.csv`、`charge-species.csv`、JSON、PHREEQC 原始输入输出、数据库与源码快照及 `reproduce.jl`。`analysis.json` 保留确定性科学载荷，`results.json` 保留时间、路径等运行溯源。

守恒检查独立计数 HCl／NaOH 的原子：Ca/F/C/Na/Cl 初始量对照用户 mol/kgw × 初始水 kg；H/O 初始量取引擎库存，随后核对新增原子，包含水中的 H/O。每步都使用实际水质量，不能把 molality 当成总摩尔数。中性添加还核对总净电荷是否保持初始残差。数值守恒容差显式配置，不能解释成实验不确定度或热力学准确度。

电荷诊断同时给出百分数、eq、eq/kgw、meq/kgw。**0.1% 是可配置诊断阈值，不是通用水质标准**；阈值超出不证明物理不可能。解析后的每个水溶液物种及其当量贡献可查 CSV；该表来自舍入后的原始物种分布，不是另一套活度模型。

`charge_context` 区分用户声明的分析误差、部分分析、假设流体；反应后状态自动标为计算过程，不冒充新的实测分析。KnownFluid 扫描默认只按部分分析解释；可显式声明 `fluid.charge_context`。旧适配器 0.1% 告警文本、原始值、扫描与历史回归均保留，不自动改变浓度。百分数可因归一化分母变化而降低，即使净当量残差并未消除。

三类验证分别报告：引擎直接 CLI 对照、化学守恒、实验比较。已核查并登记公开方解石实验，但其观测量／边界不适配本版闭合滴定，**实验过程比较尚未完成**，没有用计算 pH 冒充测量。详见：

- [电荷语义说明](../data/validation/CHARGE_BALANCE_SEMANTICS.md)
- [原始实验筛查与不适用原因](../data/validation/EXPERIMENTAL_CASE_V040.md)
- [直接 CLI 对照](../data/validation/TITRATION_ENGINE_COMPARISON.md)
- [v0.4.0 执行记录](../data/validation/V040_STATUS.md)

## v0.5.0：Reactive Mineral Path Explorer

```sh
julia --project=. scripts/paths.jl examples/reactive_paths.toml results
```

该示例完成一项完整任务：相同明确流体、两条显式候选路径、一个有来源标识的事件 DAG → 逐步真实计算与联合守恒 → 检查用户事件对应关系 → 导出独立报告。**示例中的流体、纹理观测、源编号和过程全部是 SYNTHETIC / SIMULATED，不是天然标本或实测成矿历史。** 两条路径故意改变相接触顺序，模型还检查相应反应是否实际发生；不把这个人为顺序当成独立预测。

API：`PathStudy(spec)`／`load_paths(path)`、`compare_paths(study, config; root=...)`、`report(comparison)`。没有连续优化器、路径参数自动生成、AI 成矿故事或界面开发。

### 显式物理边界与反应

- 当前只接受 `boundary = "closed_aqueous_and_retained_solids_no_gas"`：水相加用户声明的固相库存封闭；无隐式 CO2、混合、围岩、载体水或气液交换。“封闭”指元素库存；温度由外部恒温条件控制，并非绝热体系，也未计算能量／焓平衡。
- `phases` 中逐相填写 `mineral`、`initial_mol`、`target_si`、`direction`、`source_id`。支持 Calcite、Fluorite；禁止用默认 10 mol 替代未知库存。
- `direction` 为 `precipitation_only`、`dissolution_only`、`bidirectional`，直接传给 PHREEQC EQUILIBRIUM_PHASES 的对应权限。初始量为零的双向相可沉淀，但不能凭空溶解；耗尽相不保证达到目标 SI。
- 每个操作必须填写 `active_phases`，包括明确的空列表。非接触固相暂时隔离但保留在总库存内，不被悄悄删除或自动反应；这本身是过程假设，不是已知天然行为。
- 支持 `temperature`、`equilibrium`、`HCl`、`NaOH` 操作。温度序列写成多条 temperature 操作；每条的单位字段为 `temperature_c`，范围仍为显式接受的 25–80 °C 探索范围。HCl／NaOH 添加使用非负 `amount_mol` 和明确的无载体水模型。
- PHREEQC 每步保存完整 SOLUTION_RAW，再由下一步读取；不根据上一步 pH／总量重建近似流体。矿物库存取高精度 EQUI 输出，按相权限继续；每次保存和重读的状态都有 SHA-256。

正 `solid_gain_mol` 表示沉淀，负值表示溶解；`aqueous_transfer_formula_mol` 取相反号。这些是指定平衡模型的反应量，不是观测结晶量、沉淀速率或地质持续时间。

联合元素余额逐步核对：水相 moles + 全部接触／隔离固相 moles × 化学式 = 初始库存 + 明确的中性试剂添加。包括 H/O 水库存；H/O 初始水相库存取引擎值，其余初始水相量对照用户 mol/kgw × kg water。净电荷和相方向权限也必须通过。守恒或权限失败是硬约束，不允许用证据拟合分数抵偿，并停止该候选后续计算。

### 三层证据与候选分类

- **Level 1 — Saturation opportunity**：操作结束的 SI 过饱和，仅是机会；未定义 SI 保留为 unknown。不会从首次 SI > 0 生成任何时间边。
- **Level 2 — Equilibrium reaction**：指定相权限下的真实固相增减。相反应阈值必须高于绝对数值记账容差；同一批平衡步骤无法确定内部结晶先后。
- **Level 3 — Observed event**：用户独立输入的事件、来源、分类和纹理解释；不能由模型自动升级生成。

`events` 显式区分 formation／dissolution，重复矿物使用不同 ID。`evidence` 由现有 EvidenceGraph 校验；循环抛出原有 CycleConflict，不删除边。每个候选的 `bindings` 指明 event_id、operation_id 和 level。反应对应必须声明 minimum_mol；机会对应声明 minimum_si。不能把溶解事件冒充形成事件，也不会自动寻找更有利的事件对应。

分类为 compatible／incompatible／undetermined，并逐项列出原始边、源编号、模型反应量和判断原因。compatible 仅表示在指定假说与对应关系下相容；不是地质确认。机会级对应、缺失事件来源、未映射事件、同一步骤的内部顺序、严格模式下未验证模型等保留为 undetermined。已建模对应关系反转独立时间边或违反硬化学约束，则该具体候选不相容；不等于排除所有可能流体历史。

目前模型适用性仍未完整独立验证。`evaluation_mode = "strict"` 因此不能将候选认证为已验证可行；示例显式使用 exploratory，且声明 0.5% 教学诊断策略。它不改变旧配置的 0.1% 告警和任何历史容差，也不是通用分析标准或对自然数据的拟合。

报告包含路径操作图、pH／温度／SI／相反应量图、证据 DAG、准确的分类理由、CSV 联合余额、完整原始输入输出、每步状态快照、数据库／源码／证据摘要和复现脚本。`analysis.json` 排除运行目录等非科学变化，保留确定性的数值与约束判断。

### 独立实验状态

已核查 Brown–Roberson (1977) 的原始长期萤石溶解实验与原始数据表，并完成其零离子强度 log K 派生观测量的有限对照；**没有把这项参数一致性冒充完整反应路径的实验验证**。初始碳与气体边界不充分的封闭路径基准被明确拒绝，未补造 pH 或碳浓度。详见 [路径验证说明](../data/validation/REACTIVE_PATH_VALIDATION.md)、[真实数据登记](../data/validation/fluorite-experimental-case-v050.json) 和 [v0.5.0 执行记录](../data/validation/V050_STATUS.md)。
