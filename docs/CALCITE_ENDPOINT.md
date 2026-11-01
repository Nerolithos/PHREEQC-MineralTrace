# 独立方解石平衡终点对照

```sh
julia --project=. scripts/validate_calcite_endpoint.jl results
```

需要 README 中的 PHREEQC 引擎与冻结数据库。命令生成独立 HTML、实测点／模型点散点图、两种质量归一化的误差 CSV、全部原始计算和守恒结果、来源与协议快照以及 reproduce.jl。

这是对 2023 年独立实验的**定量检验**，不是必须通过的拟合测试。五个测量点在计算前冻结；当前模型系统性高估，结果完整保留。kg 水基准的误差约 +15–29%，kg 最终溶液基准约 +13–25%。图中的 ±0.03 g/kg 只是提取精度界限，不是实验置信区间。

完整条件、测量来源、原始图示、缺失元数据、预定参数和误差解释见[实验状态](../data/validation/EXPERIMENTAL_CASE_V070.md)。精确重建仍受每点固相量、质量基准和原始分析不确定度不足的限制；不能声称验证了整条反应时间路径。

## 独立的最小气体边界

`CalciteCO2Endpoint` 是只针对“脱气去离子水近似为纯水 + 方解石 + 受控 CO₂ 分压”的终点接口。它要求显式 opt-in、温度、总压力、CO₂ 分压、初始水质量、固相量、数值气库量和来源。温度保持实测 24 °C，不替换为 25 °C。这个有界测试接口接受 23–80 °C 的显式条件，但未据此认证整个范围。

PHREEQC 原生 EQUILIBRIUM_PHASES 使用 CO₂ 分压并计算 Peng–Robinson 非理想气体修正；不把分压误作逸度。数值气库必须有剩余，固相必须未耗尽且达到平衡。水相、保留方解石与数值 CO₂ 库的 Ca/C/H/O 和电荷均核对；气体交换不能当成质量守恒失败，也不能遗漏不记账。

纯水初始化显式使用电中性 pH 求解，仅适用于未加入溶质的水模型；接口不接收天然流体或实测离子分析，不会替测量数据做电荷修正。这里不支持盐溶液、有限气帽、混合、逸散时间路径或动力学。

原始发现接口的“无气相、1 atm、25–80 °C 探索假设”保持不变。不得将这个高 CO₂ 压力终点检验自动推广到 Ca–F–C 发现结果，尤其不能将 strict 模式改成模型已验证。

## 科学复现

导出文件夹内运行：

```sh
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl
```

数据库来自归档，版本与输入摘要可核查；comparison.csv 和 analysis.json 用于比较确定性数值，results.json 另带运行路径和引擎归档。原始 PDF 为 CC-BY-4.0 来源资料，项目代码 MIT 不取代其许可证。

可选的图示数据提取审计使用 Python 的 pypdf 和 Pillow：

```sh
python scripts/check_reflect_digitization.py
```

这不是 Julia 核心依赖。脚本从原始嵌入图定位同一批五个测量标记，核对冻结 CSV，不覆盖测量文件或改选误差较小的点。
