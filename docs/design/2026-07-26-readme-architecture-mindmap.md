# README 架构思维导图（Lane A）

> 目的：让访客打开 README 一眼看到仓库分层与技能分布。  
> 落地：图已写入根 `README.md`「架构一览」；本文件保留设计意图。

## 设计选择

| 选择 | 理由 |
|------|------|
| **四块 subgraph「云团」** | Cursor 不支持 mindmap；大树 flowchart 会横向挤扁 |
| 云内少连线、用 `ROOT --- 云` | 聚拢成团，而不是蜘蛛网 |
| Skills 只留两行摘要 | 细节靠下方表格 / 目录树 |
| 另附一条短主链 LR | 补「怎么跑」 |

## 非目标

- 不替代 `skills/orchestration/build-loop/workflows/recommended.md` 工作流菜单（见 ADR-001）  
- 不画 MCP/插件细节（见 `docs/mcp-presets.md`）  
