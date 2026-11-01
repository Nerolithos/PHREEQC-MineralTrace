# MineralTrace.jl — Reactive Mineral Path Explorer

**把流体组成、候选化学过程与矿物事件证据放在同一份可复现报告中，检查哪些形成路径与声明的条件相容。**

MineralTrace 面向研究 Fluorite–Calcite（萤石–方解石）体系的矿物学与水溶液地球化学用户。你提供流体、反应步骤、矿物库存和有来源的事件关系；软件调用真实 PHREEQC 计算，检查化学守恒，逐项说明候选路径为何相容、不相容或无法判断。

当前源码版本 **0.5.0 · 研究预览阶段**。项目提供 Julia 包 API 和 TOML 命令行工作流；主要操作无需编写 Julia，也不需要 Web 服务器。完整反应路径的独立实验验证仍未完成，结果不能证明天然矿物的形成历史。

[快速开始](#快速开始) · [使用自己的数据](#使用自己的数据) · [科学边界](#科学边界与验证状态) · [详细参考](docs/REFERENCE.md) · [版本与发布](#版本与发布)

## 用它研究什么

例如：同一初始流体在降温过程中，先与萤石接触、再与方解石接触，与相反接触顺序分别产生什么反应？在明确的事件对应关系下，哪条候选与用户提供的“萤石早于方解石”证据冲突？

MineralTrace 将这个问题拆成可审查的化学计算与证据检查。接触顺序和事件对应是输入假说，模型检查反应是否发生，以及该假说是否与证据一致；不会自动从矿物名称推断历史。

| 你的问题 | 入口与示例 | 主要输出 |
| --- | --- | --- |
| 两条显式反应路径，哪条与事件证据相容？ | `scripts/paths.jl` · [reactive_paths.toml](examples/reactive_paths.toml) | 逐步 pH、SI、固相增减、联合余额与事件冲突原因 |
| 加酸或加碱后，流体和矿物饱和度如何变化？ | `scripts/titrate.jl` · [acid_titration.toml](examples/acid_titration.toml)、[base_titration.toml](examples/base_titration.toml) | 真实反应后的 pH、物种、SI 和守恒检查；此接口的矿物仅监测 SI |
| 哪些采样条件符合 SI 容差和外部约束？ | `scripts/mineraltrace.jl` · [evidence_constraints.toml](examples/evidence_constraints.toml) | 离散参数扫描、化学质量与逐项排除原因；采样点相互独立 |

## 快速开始

### 1. 获取源码与依赖

需要 Git、**Julia 1.10+**、**PHREEQC 3 命令行引擎及其配套数据库**。Julia 部分仅依赖标准库；PHREEQC 需单独安装。

```sh
git clone https://github.com/Nerolithos/PHREEQC-MineralTrace.git
cd PHREEQC-MineralTrace
```

从 [Julia 官网](https://julialang.org/downloads/)安装 Julia，从 [USGS 官方页面](https://www.usgs.gov/software/phreeqc-version-3)获取 PHREEQC。将以下占位路径替换为实际文件路径：

```sh
export PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc
export PHREEQC_DATABASE=/absolute/path/to/phreeqc.dat
```

上述为 macOS／Linux shell 命令。在 Windows PowerShell 中使用 `$env:PHREEQC_EXECUTABLE = 'C:\实际路径\phreeqc.exe'` 和 `$env:PHREEQC_DATABASE = 'C:\实际路径\phreeqc.dat'` 设置变量；随后执行相同 Julia 命令。Windows 尚未在本项目完成验证。

已测试环境为 Julia 1.10.10、macOS ARM64、PHREEQC 3.8.6-17100。若需要从源码编译引擎，参见[依赖安装参考](docs/REFERENCE.md#安装依赖)。不要混用未审查的数据库参数。

### 2. 运行两条候选路径

在仓库根目录执行：

```sh
julia --project=. scripts/paths.jl examples/reactive_paths.toml results
```

终端打印 `Report: …/report.html` 和每条候选的分类。用浏览器打开打印的 HTML 路径；报告内嵌 SVG，可离线阅读。缺少依赖或配置错误会明确退出；计算失败会保留归档和原因，不会生成模拟结果代替真实引擎。

**示例全部是 SYNTHETIC / SIMULATED 教学数据。** 两条路径都从 80 °C 降到 60 °C、40 °C，分别指定不同的矿物接触顺序，并使用教学事件边 `F-I → C-I`。当前参考计算中，正向候选为条件相容，反向候选与该边冲突。这演示的是指定假说的检验，不是对真实标本的年代预测。

### 3. 阅读并保留结果

先查看报告中的路径操作图与候选分类理由，再核查反应量、守恒结果和证据来源。

| 输出 | 用途 |
| --- | --- |
| `report.html`、独立 SVG | 查看 pH、温度、SI、固相增减和事件 DAG |
| `steps.csv`、`balances.csv` | 分析逐步状态与水相加固相的元素余额 |
| `analysis.json`、`results.json` | 分别读取确定性分析载荷、带运行溯源的完整结果 |
| 原始 PHREEQC 文件、状态快照、数据库与源码快照 | 审计真实反应输入及逐步状态交接 |
| `reproduce.jl` | 使用归档配置、数据库和源码重新计算 |

**保留整个运行文件夹。** 单独的 HTML 可供阅读，完整归档用于核查和复现。在导出文件夹中运行：

```sh
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl
```

可执行文件仍需自行提供；不同构建与数据库版本可能改变数值，应核对报告中的版本和摘要。

## 使用自己的数据

先复制完整示例，保留所有必填字段：

```sh
cp examples/reactive_paths.toml my_paths.toml
julia --project=. scripts/paths.jl my_paths.toml results
```

运行前逐项修改以下内容。字段定义与边界见[路径详细参考](docs/REFERENCE.md#v050reactive-mineral-path-explorer)。

1. **初始流体**：填写 Ca、F、C(4)、Na、Cl 的总浓度（mol/kgw），以及初始 pH、pe、水质量和温度。标记 `Observation` 或 `Assumption`，填写真实来源；不完整分析不能当成完整流体。
2. **固相库存**：逐相填写 `initial_mol`、`target_si` 和 `direction`。支持 `precipitation_only`、`dissolution_only`、`bidirectional`；零库存不能凭空溶解。
3. **候选操作**：明确顺序、来源和每一步的 `active_phases`，无接触相时填写 `[]`。支持 `temperature`、`equilibrium`、`HCl`、`NaOH`。药剂 `amount_mol` 为每步添加的摩尔数，不是浓度或体积。
4. **事件与证据**：为每个阶段设置独立事件 ID；用 `evidence` 声明有来源的先后关系，用每条路径的 `bindings` 明确事件与操作的对应。删除教学证据，缺失来源保持缺失，不要沿用合成来源编号。
5. **评估策略**：明确守恒数值容差、电荷诊断阈值和 strict／exploratory 模式。教学配置的 0.5% 不是水质标准；旧接口的 0.1% 也只是诊断策略。软件不会自动修改浓度以消除不平衡。

图中的操作序号不是时间。正 `solid_gain_mol` 表示模型沉淀，负值表示模型溶解；反应量不是速率、测量结晶量或地质持续时间。

### 如何理解分类

| 分类 | 含义 |
| --- | --- |
| `compatible` | 在指定化学模型、过程假说、阈值和事件对应下相容；探索模式仍带条件限定 |
| `incompatible` | 当前候选违反硬化学约束或声明的证据关系；不能外推为所有历史均不可能 |
| `undetermined` | 来源、对应、同一步骤内部顺序或模型适用性等不足以作判断 |

必须区分三层信息：**SI 过饱和是反应机会；PHREEQC 固相增减是模型反应；独立矿物观察是外部证据。** 软件不会用前两层认证第三层，也不会从首次 SI > 0 自动生成先后关系。守恒失败是硬约束，不能靠证据拟合抵偿。

## 科学边界与验证状态

当前路径模型限于简化 Ca–F–C–O–H／Na／Cl 流体与 Calcite、Fluorite，固定 1 atm。25–80 °C 是软件探索范围，25 °C 以外必须显式接受未验证温区，不能据此宣称数据库适用性已获认证。

边界为**水相加全部保留固相的元素库存封闭、无气体交换**；非接触固相保留但暂时隔离。温度由外部条件施加，不计算热量或焓平衡。HCl／NaOH 是无载体水的中性化学式添加。当前不支持真实滴定液体积与稀释、开放 CO₂、流体混合、动力学或自动地质历史反演。

| 验证层级 | 当前证据与限制 |
| --- | --- |
| 引擎一致性 | 路径与直接 PHREEQC CLI 对照通过；代表路径输出差为 0，独立归档复现的 `analysis.json` 字节一致 |
| 化学一致性 | 逐步检查水相与全部固相的 H/O/Ca/F/C/Na/Cl 库存、净电荷及反应方向；不是实验准确度证明 |
| 独立实验比较 | 已核查 Brown–Roberson (1977) 原始萤石实验并完成有限 log K 对照；缺少充分碳／气体边界，未完成完整反应路径比较 |
| 天然历史适用性 | 尚无天然矿床独立验证，当前模型适用性保持 unverified；strict 模式不会认证为已验证可行 |

v0.5.0 本地完整测试 985 项通过，既有扫描、证据图及滴定保持工作。历史手册 Example 1 的三项差异仍保留；单独的历史基准预期失败，不能通过放宽容差掩盖。数据库物种完整性、活度模型与整个温区尚未完成独立验证。

```sh
julia --project=. test/runtests.jl
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

第二条需上述 PHREEQC 环境变量。详细证据见[路径验证](data/validation/REACTIVE_PATH_VALIDATION.md)、[执行记录](data/validation/V050_STATUS.md)、[电荷语义](data/validation/CHARGE_BALANCE_SEMANTICS.md)和[历史差异调查](data/validation/EXAMPLE1_INVESTIGATION.md)。

## Julia API

在本仓库项目环境中：

```julia
using MineralTrace
study = load_paths("examples/reactive_paths.toml")
comparison = compare_paths(study, PHREEQCConfig(); root="results")
report_path = report(comparison)
```

扫描、滴定与证据图 API 见[详细参考](docs/REFERENCE.md)。当前推荐克隆仓库使用，脚本和示例均位于仓库内；本 README 不假设已注册到 General，也不承诺 `Pkg.add("MineralTrace")` 可用。

## 版本与发布

| 版本 | 用户可用能力 |
| --- | --- |
| 0.5.0 | 有限矿物反应、温度路径、显式事件对应与候选比较 |
| 0.4.0 | 真实酸碱反应、元素守恒与过程报告 |
| 0.3.0 | 来源约束、严格／探索模式与逐项排除原因 |
| 早期版本 | PHREEQC 参数扫描与独立事件证据图 |

发布建议为先提供 **GitHub 研究预览 Release**，完成干净环境验证与自动化 CI 后，再评估 Julia General 注册；参见[发布评估与预览说明草稿](docs/RELEASING.md)。此建议不表示已发布或已注册。

**维护约定：每次显著版本更新，同步修改本首页的项目价值、可运行命令、输入输出、科学边界及验证状态。** 详细接口与历次记录链接到专页，避免首页只追加版本日志。发布说明应指向相应验证记录，并区分引擎、化学与实验验证。

## 许可证与资料

项目代码使用 [MIT 许可证](LICENSE)。PHREEQC、数据库及原始文献保留各自来源与条款，登记于 [data/sources](data/sources)。

[PHREEQC 官方资料](https://www.usgs.gov/software/phreeqc-version-3) · [PHREEQC 3 手册](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3.htm) · [详细功能参考](docs/REFERENCE.md)
