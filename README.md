# MineralTrace.jl — Reactive Mineral Path Explorer

**从流体与环境范围自动生成候选化学路径，用真实反应计算和矿物事件证据筛选机制，并保留多解与未知。**

MineralTrace 面向研究 Fluorite–Calcite（萤石–方解石）体系的矿物学与水溶液地球化学用户。你提供初始流体、允许过程与参数范围、矿物库存和有来源的事件关系；软件自动枚举环境操作组合，调用真实 PHREEQC 计算，检查化学守恒，逐项说明候选机制为何条件相容、不相容或无法判断。默认所有声明的矿物始终可接触，无需手工排列矿物反应顺序。

当前源码版本 **0.6.0 · 研究预览阶段**。项目提供 Julia 包 API 和 TOML 命令行工作流；主要操作无需编写 Julia，也不需要 Web 服务器。完整反应路径的独立实验验证仍未完成，结果不能证明天然矿物的形成历史。

[快速开始](#快速开始) · [使用自己的数据](#使用自己的数据) · [科学边界](#科学边界与验证状态) · [详细参考](docs/REFERENCE.md) · [版本与发布](#版本与发布)

## 用它研究什么

例如：允许冷却、酸化、碱化时，哪些过程组合能够产生萤石和方解石的显著模型反应？哪些组合的平衡反应增量代理顺序与“萤石早于方解石”的证据相容？不同机制是否产生同样的定性结果，改变参数范围后结论是否保留？

MineralTrace 将这个问题拆成有限候选生成、化学计算和证据检查。v0.6.0 不通过矿物开关拟合顺序，也不根据证据方向生成候选。自动检测的平衡反应位置只是筛选代理，**所有候选的真实结晶先后仍为无法判断**；热力学平衡不能预测成核时间。

| 你的问题 | 入口与示例 | 主要输出 |
| --- | --- | --- |
| 在声明范围内自动寻找候选机制，并检查多解与敏感性 | `scripts/discover.jl` · [discovery.toml](examples/discovery.toml) | 自动生成环境路径、三类条件筛选、定性反应组与范围／分辨率检查 |
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

### 2. 自动生成并筛选候选路径

在仓库根目录执行：

```sh
julia --project=. scripts/discover.jl examples/discovery.toml results
```

终端打印 `Report: …/report.html` 和分类汇总。用浏览器打开打印的 HTML 路径；报告内嵌 SVG，可离线阅读。缺少依赖或配置错误会明确退出；计算失败会保留归档和原因，不会生成模拟结果代替真实引擎。

**示例全部是 SYNTHETIC / SIMULATED 教学数据。** 在初始 pH 范围与离散温度／药剂剂量中，最多枚举两个环境操作；萤石与方解石始终同时开放。当前参考计算生成 210 个不同化学候选，条件筛选结果为 2 条相容、201 条不相容、7 条无法判断。两条相容候选是不同剂量的分步碱化，说明筛选并不唯一；收窄初始 pH 范围后不再保留相容候选。结果依赖声明的范围与平衡增量代理，不能视为真实标本历史。

### 3. 阅读并保留结果

先查看报告中的候选机制表与分类理由，再核查反应量、守恒结果和证据来源。

| 输出 | 用途 |
| --- | --- |
| `report.html`、独立 SVG | 查看 pH、温度、SI、固相增减和事件 DAG |
| `candidates.csv`、`sensitivity.json`、`response-groups.json` | 查看全部候选、网格敏感性和非唯一的定性反应组 |
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
cp examples/discovery.toml my_discovery.toml
julia --project=. scripts/discover.jl my_discovery.toml results
```

运行前逐项修改以下内容。完整规则见 [v0.6.0 使用说明](docs/DISCOVERY.md)。

1. **初始流体**：填写 Ca、F、C(4)、Na、Cl 总浓度（mol/kgw），以及初始 pH、pe、水质量和温度；保留事实／假设分类与来源。采样情景标为假设，原始测量不会被覆盖或补齐。
2. **固相库存**：逐相声明初始 mol、目标 SI、方向和来源。所有声明相在共同初始平衡和每一步均可接触；发现接口不接收 `active_phases`、手工路径或事件绑定。
3. **搜索空间**：选择 cooling、HCl、NaOH、equilibrium，声明温度与剂量样点、最大深度及累计添加上限。`max_candidates` 超限会在计算前拒绝，不截取“最优”结果。
4. **证据**：填写独立事件 ID 和有来源的先后边。删除示例的合成来源；重复矿物阶段或缺失来源保持无法判断，不自动猜测对应关系。
5. **敏感性与策略**：提供 baseline、resolution、range 三组网格，分别比较原范围、同边界细化和初始范围变化；声明反应阈值、守恒容差和电荷诊断策略。示例 5% 只是假设流体的教学诊断阈值，不是通用分析标准；软件不会自动修正离子浓度。

存在独立地质依据、需要阶段性隔离矿物时，仍可使用旧版 [手工路径接口](examples/reactive_paths.toml)。这些相接触假设必须单独解释，不能与统一可接触条件下的化学差异混为一谈。

图中的操作序号不是时间。正 `solid_gain_mol` 表示模型沉淀，负值表示模型溶解；反应量不是速率、测量结晶量或地质持续时间。

### 如何理解分类

| 分类 | 含义 |
| --- | --- |
| `compatible` | 所需模型反应与平衡增量代理顺序满足声明条件；不认证观察到的形成顺序 |
| `incompatible` | 违反硬化学约束，或缺少所需模型反应／代理顺序反转；仅排除当前有限模型筛选条件 |
| `undetermined` | 初始平衡已有反应、同批反应、重复阶段、来源或模型适用性等不足以判断 |

**三类标签针对条件机制筛选；真实形成顺序单独标为 `undetermined`。** 初次超过固相增量阈值不是成核时刻，代理不相容也不能直接推翻独立地质观察。软件不生成观测事实或时间边，不强选唯一解释。

SI 过饱和是机会、固相增减是平衡模型反应、矿物学观察是外部证据。守恒失败是硬约束，不能靠证据拟合抵偿。定性反应组相同不意味着数值轨迹相同；分类数量不是概率。细化没有改变定性组也不能证明连续参数域收敛。

## 科学边界与验证状态

当前路径模型限于简化 Ca–F–C–O–H／Na／Cl 流体与 Calcite、Fluorite，固定 1 atm。25–80 °C 是软件探索范围，25 °C 以外必须显式接受未验证温区，不能据此宣称数据库适用性已获认证。

边界为**水相加全部保留固相的元素库存封闭、无气体交换**；v0.6.0 发现接口所有声明相始终可接触，旧版手工路径才允许明确隔离。温度由外部条件施加，不计算热量或焓平衡。HCl／NaOH 是无载体水的中性化学式添加。当前不支持真实滴定液体积与稀释、开放 CO₂、流体混合、动力学或自动地质历史反演。

| 验证层级 | 当前证据与限制 |
| --- | --- |
| 引擎一致性 | 路径与直接 PHREEQC CLI 对照通过；代表路径输出差为 0，独立归档复现的 `analysis.json` 字节一致 |
| 化学一致性 | 逐步检查水相与全部固相的 H/O/Ca/F/C/Na/Cl 库存、净电荷及反应方向；不是实验准确度证明 |
| 独立实验比较 | 保留有限 log K 对照，新增方解石原始实验筛查；电解质、载体水／表面过程或有限气相不匹配，完整反应路径比较仍未完成，见[实验状态](data/validation/EXPERIMENTAL_CASE_V060.md) |
| 天然历史适用性 | 尚无天然矿床独立验证，当前模型适用性保持 unverified；strict 模式不会认证为已验证可行 |

v0.6.0 新增候选生成独立性、统一相接触、三类筛选语义、敏感性及真实引擎对照测试；既有扫描、证据图、滴定和手工路径回归保持工作。历史手册 Example 1 的三项差异仍保留；单独的历史基准预期失败，不能通过放宽容差掩盖。数据库物种完整性、活度模型与整个温区尚未完成独立验证。

```sh
julia --project=. test/runtests.jl
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

第二条需上述 PHREEQC 环境变量。详细证据见[路径验证](data/validation/REACTIVE_PATH_VALIDATION.md)、[v0.6.0 执行记录](data/validation/V060_STATUS.md)、[电荷语义](data/validation/CHARGE_BALANCE_SEMANTICS.md)和[历史差异调查](data/validation/EXAMPLE1_INVESTIGATION.md)。

## Julia API

在本仓库项目环境中：

```julia
using MineralTrace
study = load_discovery("examples/discovery.toml")
generated = generate_candidates(study) # 只生成清单，不调用引擎
result = discover_paths(study, PHREEQCConfig(); root="results")
report_path = report(result)
```

发现接口见 [使用说明](docs/DISCOVERY.md)；扫描、滴定与证据图 API 见[详细参考](docs/REFERENCE.md)。当前推荐克隆仓库使用，脚本和示例均位于仓库内；本 README 不假设已注册到 General，也不承诺 `Pkg.add("MineralTrace")` 可用。

## 版本与发布

| 版本 | 用户可用能力 |
| --- | --- |
| 0.6.0 | 自动环境路径枚举、始终可接触相、反应代理筛选、多解与参数网格敏感性 |
| 0.5.0 | 有限矿物反应、温度路径、显式事件对应与候选比较 |
| 0.4.0 | 真实酸碱反应、元素守恒与过程报告 |
| 0.3.0 | 来源约束、严格／探索模式与逐项排除原因 |
| 早期版本 | PHREEQC 参数扫描与独立事件证据图 |

发布建议为先提供 **GitHub 研究预览 Release**，完成干净环境验证与自动化 CI 后，再评估 Julia General 注册；参见[发布评估与预览说明草稿](docs/RELEASING.md)。此建议不表示已发布或已注册。

**维护约定：每次显著版本更新，同步修改本首页的项目价值、可运行命令、输入输出、科学边界及验证状态。** 详细接口与历次记录链接到专页，避免首页只追加版本日志。发布说明应指向相应验证记录，并区分引擎、化学与实验验证。

## 许可证与资料

项目代码使用 [MIT 许可证](LICENSE)。PHREEQC、数据库及原始文献保留各自来源与条款，登记于 [data/sources](data/sources)。

[PHREEQC 官方资料](https://www.usgs.gov/software/phreeqc-version-3) · [PHREEQC 3 手册](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3.htm) · [详细功能参考](docs/REFERENCE.md)
