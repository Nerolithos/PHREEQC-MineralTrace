# 发布评估与维护流程

评估日期：2026-11-09。当前源码为 v0.8.1，新增[第二组独立来源实验比较](INDEPENDENT_EXPERIMENT.md)，严格数据库校准留出资格仍待确认，没有实验验证升级。v0.8.0 已增加[模型验证与适用性](SCIENTIFIC_VALIDATION.md)、候选注释与官方引擎基准；REFLECT 仍为 experimentally challenged，未据此认证连续范围或路径。v0.7.1 已完成五点实验偏差的受控归因、原文定义审计和适用性证据登记，见[归因报告](../data/validation/v071/REPORT.md)。v0.7.0 已完成独立终点定量挑战、稳健性分析和历史差异归因；见[稳健性说明](ROBUSTNESS.md)及 [v0.7.0 状态](../data/validation/V070_STATUS.md)。终点比较发现系统偏差，不能宣传为实验验证通过。本文是本地发布建议与说明草稿，不代表已创建 GitHub Release、远端标签或 General 注册。本次检查的是本地工作区及官方发布规则，没有确认远端最新发布状态。

## 建议：先发布研究预览，再评估注册

MineralTrace 已有能够演示实际研究问题的端到端工作流，适合向小范围矿物学与地球化学用户提供可复现的研究预览。GitHub Release 可以固定源码版本并附验证材料，便于用户引用问题所发生的版本。

Julia package 与 GitHub Release 是不同事项：本仓库已具有 Project.toml、src/MineralTrace.jl 和测试入口，是可从项目环境加载的 Julia 包。General 注册进一步提供按名称安装与版本解析；无需注册也可通过仓库 URL 安装包，见 [General 官方说明](https://github.com/JuliaRegistries/General/blob/master/README.md)与 [Pkg 官方文档](https://pkgdocs.julialang.org/v1/managing-packages/)。URL 安装库本身不能替代获取本项目的脚本和示例，当前面向用户的推荐方式仍是克隆仓库。

暂缓注册是本项目的维护判断，不是注册表要求所有科学模型先获实验认证。注册不会认证科学正确性。当前更急迫的缺口是干净环境安装验证、自动化 CI、外部引擎配置体验与持续 API 维护。

## 本地就绪情况

| 项目 | 检查结果与行动 |
| --- | --- |
| 包结构、版本、许可 | Project.toml 标为 0.8.1、Julia compat 为 1.10，已有 MIT LICENSE |
| 用户入口 | README 已改为路径工作流优先，保留扫描与滴定入口、依赖配置、复现和局限 |
| 本地验证 | v0.8.0 完整回归通过，另有档案／候选注释／官方基准定向检查；35 个终点守恒及科学报告、官方基准、发现归档三类独立复现一致。实验偏差另报 |
| 自动化 CI | 本地未见 .github/workflows；发布前应加入基础测试和固定引擎／数据库的真实集成测试 |
| 干净环境 | 应在未依赖开发者 /tmp 文件的环境中，验证下载、安装、路径配置、示例和归档复现 |
| 变更归档 | 当前 v0.8.1 有未提交／未跟踪文件；发布前须完整纳入确定的提交，防止标签遗漏实现与数据 |
| 数据与附件 | 原始文献、数据库与代码分开保留来源／条款；检查 Release 附件的再分发条件，不把 MIT 推广到全部外部资料 |
| 科学限制 | 完整独立实验路径验证未完成；保留历史基准三项已知差异，不宣传为已验证历史推断工具 |

CI 与干净环境验证是本项目建议的发布质量门槛；当前没有将建议写成已完成事项。

## v0.5.0 预览说明历史草稿（未发布）

以下草稿描述 v0.5.0 手工路径工作流。若发布当前 v0.7.0，应改用自动候选生成、固定相可接触性、多解与敏感性说明，并明确平衡代理与实际形成顺序的区别；版本、验证数字及源码快照必须重新核对。不得将以下旧草稿直接作为当前发布说明。

建议标题：**MineralTrace v0.5.0 — Reactive Mineral Path Explorer (Research Preview)**。

在 GitHub Release 中勾选预发布标志。最终标签与 Project.toml 保持一致；若决定采用 `v0.5.0-rc1` 一类候选标签，应先同步包版本和相关文档，不混用两个版本身份。GitHub 的预发布标志与版本字符串分属不同设置，见 [GitHub 发布管理文档](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases)。

可使用以下发布说明：

> 本版将流体组成、有限矿物库存、显式化学操作和用户事件证据结合到同一份可复现报告中。支持 Calcite／Fluorite 平衡反应、受控温度路径及 HCl／NaOH 化学式添加；逐步检查水相与固相元素库存、净电荷和反应方向。
>
> 从 README 的双路径合成示例开始。报告提供 pH／SI／固相增减图、候选冲突理由、CSV、原始 PHREEQC 状态与复现脚本。运行需要单独安装 Julia 和 PHREEQC CLI；保留既有参数扫描、证据图与酸碱滴定功能。
>
> 这是研究预览。接触顺序与事件对应是用户假说，模型不能认证天然形成历史。局部 log K 文献比较已完成，完整独立实验路径验证尚未完成；数据库／温区适用性仍有限，严格评估不会将模型标为已验证。
>
> 验证：本地 985 项测试通过；代表路径直接 PHREEQC 对照一致，归档独立复现的分析载荷字节相同。历史 Example 1 三项差异按原容差保留。详见 data/validation/V050_STATUS.md。

建议附件为一个来源、许可和运行环境均可核查的合成示例完整归档；单独 report.html 作为便捷预览。附件生成后应核对源码提交、引擎版本、数据库摘要和可复现性，不能直接把工作区中旧源码快照当成最终 Release 快照。无需捆绑本地 /tmp 下的引擎，也不宣称独立可执行安装包已完成。

## General 注册前再检查

1. 完成 CI 与干净环境验证；清楚区分无需引擎的测试和真实引擎测试。
2. 验证在独立 Julia 项目按仓库 URL 安装、加载和调用公共 API；确认未来用户如何获取示例与 CLI。
3. 明确公共 API、兼容政策与破坏性变更记录，并审查包名和当前 General 注册规则。
4. 配置 Registrator／TagBot 等维护流程，确保包版本、源码提交、标签和说明一致。
5. 保留科学适用范围与已知失败；注册不作为实验验证的替代。

这些维护事项不要求开始机器学习、扩大矿物库或增建界面。

## 每次显著版本更新

先更新 README：这个版本能帮助用户完成什么任务、最短操作路径是什么、输入输出有何变化、证据与科学边界如何变化。再更新详细参考、示例、验证记录和发布说明；用文档中的命令运行实际示例并核对输出。发布前固定提交，检查归档中源码与发布身份一致。

## v0.8.2 local release checks

Review [execution record](../data/validation/V082_STATUS.md), [scientific comparison](../data/validation/v082/REPORT.md), [reproduction audit](../data/validation/v082/REPRODUCTION_AUDIT.json) and [workbench guide](WORKBENCH.md). Build with the committed npm lockfile; configure trusted engine paths outside requests. Preserve the frozen v0.8.1 runtime/receipt and unchanged experimental inputs. The local workbench is not a public hosting target. External CI, native installers and cross-platform support are not claimed. No package registration or remote release is authorized by this development brief.
