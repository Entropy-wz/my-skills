# Docs — 从这里读

个人工具库文档入口。先走主链，再按需下钻；细则见 **[ADR-001](adr/001-toolkit-three-layer-layout.md)**。

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

## 目录

```
docs/
├── README.md     # ← 你在这里
├── adr/          # 架构决策（ADR-001 = 三层布局）
├── design/       # 设计与 intake（决议多；先读上面链接）
├── workflows/    # stub → skill-local 菜单
├── templates/    # 粘贴模板（ADR、case card、…）
└── examples/     # 脱敏样例
```

Lane A（`work-lanes` design-only）产物落在这里；实现进 `skills/` / `kits/` / `tools/`。

其他：MCP 预设 [`mcp-presets.md`](mcp-presets.md)；research case cards 见 skill `research-case-card` + `templates/enterprise-case-card.md`。
