# Docs — 从这里读

个人工具库文档入口。先走主链，再按需下钻；细则见 **[ADR-001](adr/001-toolkit-three-layer-layout.md)**、**[ADR-002](adr/002-agents-as-role-packs.md)**（agents 角色包）、**[ADR-003](adr/003-workflow-yaml-as-studio-sot.md)**（studio 双 SoT）。

## 阅读顺序

1. **主链（出站）** — 仓库根 [`README.md`](../README.md) 架构云图 + 车道语义  
   `clarify-and-plan` → Lane A/B → review → `ship-gate` → Lane C  
2. **工作流菜单** — 日常「该调哪条链」：  
   权威副本 [`skills/orchestration/build-loop/workflows/recommended.md`](../skills/orchestration/build-loop/workflows/recommended.md)  
   （本目录 stub：[`workflows/recommended.md`](workflows/recommended.md) — **只改 skill-local，勿双源编辑**）  
3. **Intake 决议** — 吸收什么、不吸收什么：  
   [`design/2026-07-26-toolkit-intake-decisions.md`](design/2026-07-26-toolkit-intake-decisions.md)  
   （目录/候选池：[`design/2026-07-25-toolkit-skill-catalog.md`](design/2026-07-25-toolkit-skill-catalog.md)）  
4. **Review 框架** — merge / code review 轴：  
   [`design/2026-07-26-review-framework.md`](design/2026-07-26-review-framework.md)  
5. **Agent Flow Studio（Phase 2）** — 图画板双向工作台：  
   [`design/2026-07-27-agent-flow-studio.md`](design/2026-07-27-agent-flow-studio.md)  
   （计划 [`design/plans/2026-07-27-agent-flow-studio.md`](design/plans/2026-07-27-agent-flow-studio.md)；D1：`ship-review` 迁移不覆盖手写 `AGENT.md`）

## 目录

```
docs/
├── README.md     # ← 你在这里
├── adr/          # 架构决策（ADR-001…003）
├── design/       # 设计 / intake；含 agent-workflow-fields、studio
├── workflows/    # stub → skill-local 菜单
├── templates/    # 粘贴模板（ADR、case card、…）
└── examples/     # 脱敏样例
```

Lane A（`work-lanes` design-only）产物落在这里；实现进 `skills/` / `kits/` / `tools/`；角色包 SoT 在仓库根 `agents/`。  
（`docs/agents/` 留给 work-lanes / mattpocock 类流程文档，勿放 role-pack 清单。）

其他：MCP 预设 [`mcp-presets.md`](mcp-presets.md)；research case cards 见 skill `research-case-card` + `templates/enterprise-case-card.md`；  
workflow 字段清单 [`design/agent-workflow-fields.md`](design/agent-workflow-fields.md)。
