# README figure provenance / 首页图示来源

`compatibility-plane.svg` is copied byte-for-byte from the actual v0.7.0 robustness calculation. It is a repository-native scientific SVG, not an AI illustration, mockup or unmeasured experimental plot.

`compatibility-plane.svg` 来自 v0.7.0 实际稳健性计算，逐字节复制；是计算生成的科学 SVG，不是 AI 插画、界面效果图或虚构实验结果。

- Source study / 原始研究：`results/discovery-qktTgC/sampled-compatibility.svg` (local ignored run archive).
- Reproduce / 重算：`julia --project=. scripts/robustness.jl examples/discovery.toml examples/robustness.toml results`.
- Inputs / 输入：[discovery.toml](../../../examples/discovery.toml), [robustness.toml](../../../examples/robustness.toml).
- Slice / 切片：initial pH × second NaOH addition in mol; the first addition is fixed at 0.009 mol, and all other inputs/environmental sequence remain fixed.
- Study type / 数据性质：**SYNTHETIC / SIMULATED**. The event constraint, fluid recipe and process ranges are teaching assumptions, not specimen measurements.
- Meaning / 含义：10 calculated combinations; two explicitly uncomputed Cartesian combinations. Space between all points is also uncomputed. Labels are equilibrium-increment surrogate classes; actual formation chronology remains undetermined.
- Engine / 引擎：PHREEQC 3.8.6-17100; database SHA-256 `59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`.
- Figure SHA-256 / 图示摘要：`d123fbe7f0a90e129163ed8a6db82a2ddd2950ee711edcd50bf10eb5d7d86278`.
- Deterministic robustness analysis SHA-256 / 稳健性载荷摘要：`411d7df20e20474b7329364a2915bdc96ae99e051f7e77ae0b749af8dae755ee`.

[Workflow / 使用说明](../../ROBUSTNESS.md) · [Execution record / 执行记录](../../../data/validation/V070_STATUS.md) · [Export audit / 导出审计](../../../data/validation/v070-export-audit.json).

The exported run folder is not a public hosted demo. The SVG is stored here so GitHub can display it directly from a clone. Update the preview, both README captions and provenance together when its source calculation changes.

原始运行目录不是公开托管的在线演示。将 SVG 纳入仓库，便于 GitHub 和克隆副本直接展示。来源计算发生变化时，应同步更新预览图、两种语言的图注和本来源记录。
