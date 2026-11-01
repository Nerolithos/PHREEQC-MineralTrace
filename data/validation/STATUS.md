# 首轮验证记录 — 2026-11-01

本项目没有天然矿床数据验证。通过执行测试与通过科学验证是不同的状态。

## 实际运行环境

- macOS ARM64；Julia 1.10.10。
- 官方 PHREEQC 3.8.6-17100 源码，AppleClang 17.0.0、CMake Release 编译。
- 使用该发行包原样提供的 `database/phreeqc.dat`，未拼接或修改热力学参数。
- 数据库 SHA-256：`59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`。
- 本机构建可执行文件 SHA-256：`c812189a98bc4667fcccfe28387924df3cc4b63fe714a943b5c41ae2df720f4a`（其他机器编译后的二进制摘要可能不同）。
- 源码归档摘要及官方输入摘要见 `../sources/`。每次运行另保存实际输入、数据库副本和进程日志。

本轮工具位置：`/tmp/julia-1.10.10/bin/julia`、`/tmp/mineraltrace-phreeqc-build/phreeqc`、`/tmp/phreeqc-3.8.6-17100/database/phreeqc.dat`。这些不是永久安装。

## 测试结果

设置 README 中的环境变量后，执行：

```sh
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

55/55 通过，退出码 0。完整输出为 [test-output.txt](test-output.txt)。

另尝试标准入口 `julia --project=. -e 'using Pkg; Pkg.test()'`；即使设置离线模式，全新 depot 仍尝试下载默认注册表，被 DNS/网络限制阻止，退出码 1，未进入测试。日志为 [pkg-test-output.txt](pkg-test-output.txt)。上面的直接测试命令无需下载注册表。

| 分类 | 通过项数 | 含义 |
| --- | ---: | --- |
| 事件与证据 DAG | 13 | 重复矿物事件、传递关系、不确定关系、自环、循环证据、输入校验 |
| 流体输入与依赖错误 | 8 | 明确单位、固定参考条件、拒绝非法输入和缺失依赖 |
| 输出解析 | 8 | 拒绝缺失文件、列缺失、行不完整、重复列、非有限值及未定义相哨兵 |
| 真实 PHREEQC 执行 | 10 | Example 1 可运行、归档摘要、Ca/F/C 演示计算、电荷告警、错误和未知相拒绝；不包括历史数值一致性 |
| 官方 Example 2 对照 | 4 | 51 个反应步完整读出，以及表 13 的 25 °C SI 对照 |
| 进程失败归档 | 12 | 非零退出、缺失输出、超时；仅用进程夹具，不用假化学引擎 |

`examples/forward.jl` 和 `examples/paragenesis.jl` 均实际运行成功。前者为 **SYNTHETIC / SIMULATED**，电荷误差 2.9641%，仅演示计算与告警；不能作为有效天然流体模型。后者演示一个确定关系及两个不可比较的关系。

## 官方数值基准

[Example 2，表 13](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-64.htm) 的 25 °C 反应步：

| SI | 官方表值 | 本轮输出 | 绝对容差 | 结果 |
| --- | ---: | ---: | ---: | --- |
| Gypsum | 0.00 | 0.0000 | 0.01 | 通过 |
| Anhydrite | -0.30 | -0.3045 | 0.01 | 通过 |

官方输入 `usgs-ex2.pqi` 原样留存，运行时仅将所选输出文件名改为 `selected.tsv`。这个基准验证适配器读取平衡计算输出的路径，**不验证整个温度扫描，也不验证 Ca–F–C 体系全部热力学行为**。

[Example 1，表 11](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-63.htm) 与当前发行包数据库的对照 **失败**：

| SI | 官方表值 | 本轮输出 | 绝对容差 | 结果 |
| --- | ---: | ---: | ---: | --- |
| Calcite | 0.68 | 0.7852558919 | 0.01 | 失败 |
| Gypsum | -0.64 | -0.8021685199 | 0.01 | 失败 |
| Anhydrite | -0.92 | -1.0900416796 | 0.01 | 失败 |

运行 `julia --project=. scripts/benchmark.jl` 会复现以上三个失败，退出码 1。完整日志为 [legacy-benchmark-output.txt](legacy-benchmark-output.txt)。该命令在失败测试集结束后停止，因此不代表其后的测试已执行。常规集成测试明确提示未执行此项对照；不会把它计入通过数。

Example 1 官方输入原样复制自本轮发行包；运行时只在 END 前增加 SELECTED_OUTPUT。差异原因尚未确认，不能归因于某一个数据库参数；也未扩大容差或用本次输出重建参考答案。

## 当前不能声称的结论

- 不能声称 Milestone 2 已全面完成：Example 1 数值复现仍受阻。
- 未验证高温热液条件、全部相关物种和活度模型适用范围。
- 未完成完整的物质守恒验证、反演恢复、多解性测试和独立天然案例验证。
- 未从任何计算推断矿物的真实形成温度或生成历史。
- 当前没有自动研究报告、图像输出、环境反演或检测推荐功能。

下一步优先调查历史参考与当前数据库的差异，获取可追溯且版本匹配的官方参考输出；随后验证 Ca–F–C 体系的物种完整性和温度范围，再进入网格反演。
