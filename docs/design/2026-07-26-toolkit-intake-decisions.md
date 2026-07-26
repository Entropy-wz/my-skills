# 工具库吸收决议（选型落地设计）

> **状态**：Lane B 已按 Wave 0a→4 落地（2026-07-26）；以仓库内 skills/kits/docs 为准。出站另开 Lane C + ship-gate。
> **依据**：你对 `2026-07-25-toolkit-skill-catalog.md` 的回复（2026-07-26）。  
> **原则**：改造融入，不整包搬迁；显式触发（`disable-model-invocation` 优先）；与 work-lanes / ship-gate 交接清晰。  
> **已确认（2026-07-26）**：文档模式 **T + P + D**；`build-loop` **保留为薄入口**，打开工作流说明（不删除目录）。

---

## 0. Triage vs work-lanes（你问的确认）

| | **Matt `triage`** | **我们的 `work-lanes`** |
|--|-------------------|-------------------------|
| 方向 | **Inbox**：外来 issue / 外部 PR 是否就绪 | **Outbox**：我的工作如何离开本机 |
| GitHub | 分类、核实、grill、写出 `ready-for-agent` brief；状态机/标签 | Lane C 才 `gh issue create` / `gh pr`；umbrella+child；**禁止** Lane A 建远程 issue |
| 结论 | **思想互补，并未实现** | 已实现出站纪律 |

work-lanes 原文已写：*Triage = inbox readiness；work-lanes = outbox discipline*。  
**决议**：**不单独进库 Matt triage**。若以后要「审外来 PR/issue」，再开薄 skill `inbox-triage`，或把 4 步清单写进 `docs/agents/` —— 本次不做。

---

## 非目标（Non-goals）— 本次明确不做

防范围蔓延，以下均**不在本设计交付范围**，出现相关需求时另开 Lane A：

1. **不整包 fork / vendor 上游仓库**（Superpowers、Matt、awesome、Sentry 等）进 `skills/`；只做 A（对照吸收）/ B（精简改写）。
2. **不进库 Matt `triage`**（§0）；`ask-matt`、`wayfinder`、`to-spec`、`to-tickets`、`setup-matt-pocock-skills` 等整包路由/票据流同不进。
3. **不 vendor MCP 服务器源码**、不建 `kits/mcp-presets` 重包装；MCP 走本机安装 + `docs/mcp-presets.md`（§2.16）。
4. **不做第二 IDE Agent 包装**（Aider / Continue / Cline / Copilot 等，catalog Ch8）；仍押注 Cursor。
5. **不新建与现有 review 并列的第 4 套 review**；安全/缺陷/TDD 作为**轴**挂进现有 review（§2.10）。
6. **不把 `grinding-until-pass`、`babysitting-pr`、纯终端玩具** 单独进库（§2.8）。
7. **不删除 `skills/build-loop` 目录**（改薄入口，§2.2）；**不改动** work-lanes / ship-gate 的车道语义与 gate 契约，只补交接引用。
8. **不实现任何 skill/kit 代码**——本文件是 Lane A 设计稿，落地属 Lane B。

---

## 1. 目标形态（吸收后主链）

```
clarify-and-plan          ← 澄清 + grill + 设计过审 + writing-plans
        │
        ▼
work-lanes A →（ADR / design doc / plan）
        │
        ▼
work-lanes B
  ├ systematic-debugging     （fix）
  ├ multi-task-protocol      （多任务 / 子代理执行约定）
  ├ using-git-worktrees      （隔离 / 可选 hard-problem）
  ├ frontend-craft           （前端）
  └ document-delivery        （文档三类产物）
        │
        ▼
review 框架
  ├ merge-code-review（+ 收评审附录）
  ├ code-review（通用场景）
  ├ security / find-bugs 轴   （Ch7）
  └ improve-codebase-architecture（架构向，非合并门）
        │
        ▼
pre-commit / git-guardrails  →  ship-gate  →  work-lanes C
（事故：incident-response；库维护：skill-fit / skill-gardening）
```

`build-loop`：**降级为工作流介绍**（非生产编排 skill），见 §3。

**主链读法（避免误解为串行外挂）**：`clarify-and-plan` 不是 work-lanes 之前的独立阶段，而是 **Lane A 内部使用的方法**——它产出的 `docs/design/*` 与 `docs/design/plans/*` 就是 Lane A 的合法产物。work-lanes 管「车道 / 远程纪律」，clarify-and-plan 管「Lane A 里怎么把设计与计划做扎实」。二者是**编排层 vs 车道层**，不是先后两步。上图箭头表示信息流，不表示所有权切换。

---

## 2. 新 / 改 Skill 与 Kit 清单

### 2.1 `skills/clarify-and-plan`（新建，P0）

**合并来源**：Superpowers `brainstorming` + `writing-plans` + Matt `grill-me` / `grilling` / `grill-with-docs`（精髓，非原文搬运）。

**阶段（硬门）**

1. 读上下文（repo docs / 近 commit）  
2. **一次一问**澄清目的 / 约束 / 成功标准（可进入 grill 模式加压假设）  
3. 提出 2–3 方案 + 取舍 + 推荐  
4. **分段**呈现设计，每段等人点头  
5. 落盘设计：`docs/design/YYYY-MM-DD-<topic>.md`  
6. 自检（占位符 / 矛盾 / 范围）→ 请人审文件  
7. **写作计划**：`docs/design/plans/YYYY-MM-DD-<topic>.md`（零上下文可执行、咬口任务、YAGNI）  
8. 若决策难逆 / 多方案权衡 → 提醒或起草 **ADR**（§2.8）  
9. **禁止**未批准设计与计划就写实现代码（热修 / 用户显式跳过除外，须口述）

**grill-with-docs**：grill 过程中可顺带改 glossary / ADR 草稿，不另立 skill。

**触发语示例**：`clarify-and-plan` / `澄清并对齐` / `先设计再计划` / `grill 一下这个方案`

---

### 2.2 `build-loop` → 薄入口 + 工作流说明（降级，P0）**【已确认】**

| 现在 | 之后 |
|------|------|
| 生产编排 skill（frame→propose→implement→test→review） | **`skills/build-loop`** 保留目录，改为**薄入口**：加载并展示 `docs/workflows/recommended.md`，按场景列出推荐 skill 链；**不**再执行 frame→implement 编排 |

**`docs/workflows/recommended.md` 菜单项（示例）**

- 新功能：`clarify-and-plan` → Lane A → Lane B → review → `ship-gate` → Lane C  
- Bug：`systematic-debugging` → Lane B → review → ship-gate → Lane C  
- 前端：… + `frontend-craft`  
- 文档交付：`document-delivery`（模式 **T / P / D**）  
- 多任务实现：`multi-task-protocol`  
- 事故：`incident-response`  

薄入口行为：读工作流文档 → 用当前用户意图匹配一条推荐链 → 告知该调哪些 skill；**禁止**自行代替那些 skill 做实现循环。

**旧 build-loop 能力的去向（务必逐条落位，勿默认「已被吸收」）**：

| 旧能力 | 去向 | 备注 |
|--------|------|------|
| 多任务 / 子代理派工 + 任务后 review | `skills/multi-task-protocol`（§2.3） | 仅覆盖「多任务」场景 |
| 有界重试测试环（≤3 次 fix 后停） | **`docs/workflows/recommended.md` 明文写入** + fix 走 `systematic-debugging` | ⚠️ 这条**不属于** multi-task；单任务实现若无此明文将丢失「不无限修」纪律 |
| 「先给 ≥2 方案再实现」硬门 | 设计期归 `clarify-and-plan`（§2.1）；实现期在 recommended.md 提示 | build-loop 原 Phase2→3 门不再由 skill 强制 |
| frame→propose→implement→test→review 单任务编排 | 拆散到上述各处，**不保留**单一编排 skill | 已确认降级为薄入口 |

迁移（Wave 0 必做，见 §3 DoD）：`skills/ship-gate`（"When not"、Boundaries 表中的 `build-loop Phase 5` 引用）、`skills/merge-code-review`、catalog 等凡写「经 build-loop 实现 / build-loop Phase N」的，改为「见 `docs/workflows/recommended.md` / 具体 skill」。降级后这些引用会**悬空**，必须同波修正。

---

### 2.3 `skills/multi-task-protocol`（新建，P0）

**来源**：Superpowers `subagent-driven-development` 精简。

**约定（生产协议，短）**

- 有书面 plan（来自 clarify-and-plan）时：按任务派工  
- 每任务：新鲜子代理（或等价隔离上下文）+ **任务后**只读 review（spec + 质量）  
- 全部完成后：一次全分支 / 宽 diff review（可挂 merge-code-review）  
- 卡住（BLOCKED / 真歧义）才停；不刷「要继续吗」  
- 与 Lane B 兼容；不碰 remote  

---

### 2.4 `skills/using-git-worktrees`（新建，P1 — 我的判断）

- 探测是否已在隔离区 → Cursor 原生 worktree / best-of-n → 否则 `git worktree`  
- 与可选 `hard-problem-mode`（best-of-n）同波或紧随  
- **不**做成默认每提交必用；触发：并行方案、脏主工作区、执行长 plan  

---

### 2.5 `skills/systematic-debugging`（新建，P0）

- Iron Law：无根因调查不改代码  
- 骨架：复现 → 隔离（二分/bisect/分层）→ 假设 → 验证 → 最小修复 + 防回归  
- 挂钩：工作流「Bug」入口；fix 类工作默认先走它  

---

### 2.6 `merge-code-review` 附录（改，P0）

新增 **Appendix: Receiving review feedback**（来自 Superpowers receiving-code-review）：

- 先读完再反应；核实再改；技术正确 > 表演式同意  
- 不清就问；有争议用证据（复现 / 测 / 规范引用）  

不新建独立 skill。

---

### 2.7 `skills/skill-fit`（新建，改造 writing-skills，P1）

**定位**：把**已有** skill / kit **改得更贴本仓库**（不是从零教写 skill 的 TDD 课）。

- 对照 `skills/_template`、work-lanes 交接、触发语、路径约定  
- 检查：与主链重复、缺「何时不用」、缺 Verification、命名漂移  
- **默认合并** Cursor-Native「building-skills-from-patterns / suggesting-rules」为 `skills/skill-fit` 内一节（"skill-gardening"），**不单独立 skill**；仅当该节明显膨胀再拆分  

---

### 2.8 Awesome / Cursor 原生（按我的意见，Ch5 → 落地名）

| 落地 | 内容 | 波次 |
|------|------|------|
| `skills/browser-verify` | verifying-in-browser + visual-qa（可含 responsive/a11y/dark 清单） | P0 随 frontend-craft |
| `skills/parallel-ci-triage` | CI 失败并行分修；ship-gate 失败可提示 | P1 |
| `skill-gardening` 能力 | suggesting-rules + building-skills-from-patterns | P1 |
| `skills/using-git-worktrees` (+ 可选 hard-problem) | 见 §2.4 | P1 |
| 跳过进库 | babysitting-pr、与 merge-CR 重复的 parallel-code-review 整包、纯终端玩具项 | — |
| grinding-until-pass | **不**独立 skill；有界重试写进工作流文档 + multi-task / debugging | — |

---

### 2.9 Matt 其余

| 项 | 决议 |
|----|------|
| grill* | 并入 `clarify-and-plan` |
| triage | **不进库**（§0） |
| tdd | 不单立；进 **Review 框架** 的「TDD / 测试充分性」检查轴 + 工作流可选模式 |
| improve-codebase-architecture | **B** → `skills/improve-codebase-architecture`（架构扫描→选项→可接 clarify grill）P1 |

---

### 2.10 Review 大框架（扩展，含 Ch7 + TDD）

现状：`code-review`（通用清单）+ `merge-code-review`（合并前正确性主轴）+ `hunk-walkthrough`。

**目标结构**（文档 + 薄 skill，避免五个平行巨兽）：

```
docs/design/…-review-framework.md   ← 总图（本次设计的一部分）
skills/
  merge-code-review     ← 合并门；附录收评审；可调用安全轴
  code-review           ← 升级为「通用 / 教学 / 快速」场景入口（非仅合并）
  # 可选薄入口（若通用 CR 不够用再拆）:
  #   review-security   或 merge-CR 内嵌 Sentry 轴
  #   review-architecture → 指向 improve-codebase-architecture
```

**Ch7 纳入方式**

| 能力 | 放哪 |
|------|------|
| systematic-debugging | 实现前/中过程门（非 CR） |
| security-review / find-bugs | Review 框架「安全/缺陷轴」；合并前可选；精简自 Sentry |
| skill-scanner | 库 CI / skill-fit 门禁（扫 `skills/**`） |
| api-smoke / e2e | 项目 gates + frontend-craft；CR 只检查「该有的测是否缺失」 |
| TDD 思想 | Review：缺测 / 未见红绿则降级信心；工作流「TDD 模式」一段说明 |

---

### 2.11 Pre-commit / git-guardrails（Kit，P1）

`kits/git-hooks/`（名可改）：

- 提交前门禁：格式化 / lint / 类型（按语言探测，可开关）  
- **护栏**：拦危险 git（force push main、`reset --hard` 未确认等）——对齐 Matt git-guardrails 思想，做成可安装 hooks  
- 与 `ship-gate` / `run-gates`：**本地 commit 前** vs **出站前** 两层，不互相替代  
- 产出：`install.ps1` / `install.sh` + README；可选薄 skill 仅说明何时安装  

---

### 2.12 `skills/incident-response` + 模板（P1）

- Skill：定级 → 缓解 → 沟通 → 解决 → 复盘  
- 模板：`docs/templates/postmortem.md`  
- 与 work-lanes：热修可**跳过完整 clarify**，但**不豁免车道 gate**——紧急推送/PR 仍走 Lane C 的 commit 卫生与 gate（可记录 override）；事后必须补 postmortem（及可选 ADR）  
- 与 systematic-debugging：事故中「缓解」优先于根因；进入根因阶段再调 `systematic-debugging`  

---

### 2.13 ADR（P0 模板 + P0/P1 薄 skill）

- `docs/templates/adr.md`  
- `docs/adr/` 编号文件 `NNN-title.md` — **锁定用 `docs/adr/`**（README 已预留；不再保留 `docs/decisions/` 备选，避免路径漂移）  
- `skills/architecture-decision-records`：何时写、模板、与 clarify-and-plan 交接（clarify-and-plan 步骤 8 触发起草，ADR skill 负责落盘规范）  
- **结构性文件**：Lane A 设计里出现难逆决策 → 应用模板落盘  

---

### 2.14 Ch4 `kits/frontend-craft` + 入口 skill（P1）

按 catalog Ch4：设计品味（Anthropic frontend-design 改造）+ Vercel 规则精选 + `browser-verify` + 可选 Playwright 烟雾 + 模板 `ui-review.md`。

**所有权（消除 kit/skill 二义）**：`kits/frontend-craft/` 承载**可运行资产**（脚本、模板、Playwright 脚手架、README）；`skills/frontend-craft/` 是**薄入口 skill**，只编排「设计约束 → 实现规范 → browser 验收」并指向 kit 资产。同名不同层：kit = 依赖物，skill = 编排入口。  
交接：`docs/workflows/recommended.md` 的「前端」菜单项指向 `skills/frontend-craft`。

---

### 2.15 文档交付框架（改造，非搬运）（P0–P1）**【已确认：T + P + D】**

| 模式 | 代号 | 用途 | 产物气质 |
|------|------|------|----------|
| 技术详尽 | **T** | API/架构/运维/研究长文 | 完整、可引用、可验证 |
| 汇报·展示 | **P** | 对外/管理层/比赛展示 | 短、叙事强、少实现细节 |
| 汇报·设计底层 | **D** | 设计评审/内部对齐 | 短、结构/取舍/接口，偏底层 |

**组件**

- `skills/document-delivery`：选模式 → 大纲过审 → 撰写 → 导出（PDF/Word/PPT/Excel 用改造后的 Anthropic 文档技能思想 + 本机工具说明）  
- `skills/doc-verify`（**默认合并** verifying-markdown + fixing-broken-links 为一篇入口两种检查；§4 保留「拆两个 skill」为备选，但波次计划按合并推进）  
- 模板：`docs/templates/doc-technical.md` / `doc-report-present.md` / `doc-report-design.md`  
- **禁止**原样 vendor 官方 SKILL 长文；只保留：结构、导出约束、质量门、与 research-case-card 的引用规范对齐  

与现有 `research-case-card`：调研卡提供证据块；document-delivery 负责成稿形态。

---

### 2.16 MCP（我的意见）

| 做 | 不做（本波） |
|----|----------------|
| `docs/mcp-presets.md`：推荐插件表、权限、env 名、与 Skill/Kit 分工（catalog Ch9 精简进库） | 不上 `kits/mcp-presets` 重包装 |
| 需要 Figma/Linear/Sentry 时 **C 本机装官方插件** | 不把 MCP 服务器源码 vendor 进库 |
| 自建 MCP 需求出现时再 B `mcp-builder` 改造版 | 不为「齐全」预建 |

SearXNG 继续 **Kit**；将来若要工具化再加薄 MCP 桥，非必须。

---

## 3. 波次计划（建议实现顺序）

**通用完成定义（每个新 skill/kit 均适用）**：① frontmatter 对齐 `skills/_template`（name/description/触发语；编排类默认 `disable-model-invocation: true`）② 含「何时用 / 何时不用」③ 与 work-lanes / ship-gate 交接一句话 ④ 路径与命名符合本文 ⑤ 通过 `scripts/check-layout.ps1`（若适用）⑥ 无悬空引用（指向的 skill/文档已存在或明标「planned」）。

> **拆波原则（防 Wave 0 过载）**：Wave 0 先分两拍——**0a 管道/降级**（不新写 skill，只理顺主链、修引用），**0b 核心新 skill**。0a 全绿再开 0b，降低「薄入口指向空 skill」的风险（见 Critical 发现）。

### Wave 0a — 管道与降级（骨架，不新写 skill）

| # | 交付 | 验收标准（Done = 可勾） |
|---|------|--------------------------|
| 1 | 本决议定稿（本文）✓ | 经子代理审核；无内部矛盾；Non-goals / DoD 就位 |
| 2 | `build-loop` 降级为薄入口 | `skills/build-loop/SKILL.md` 只「读并展示 `docs/workflows/recommended.md` + 匹配一条链」；不再执行 frame→implement；guardrails 保留「禁止代实现循环」 |
| 3 | `docs/workflows/recommended.md` | **只列已存在的 skill**；未落地项标注 `（planned Wave N）`，不产生可点击死链；明文写入「有界重试 ≤3 次」纪律（承接旧 build-loop） |
| 4 | 引用迁移 | `ship-gate`（"When not"、Boundaries 表的 `build-loop Phase 5`）、`merge-code-review`、catalog 中所有 `build-loop Phase N / 经 build-loop` 改指向 recommended.md 或具体 skill；全仓 grep `build-loop Phase` 归零 |
| 5 | `docs/README.md` 目录树 | 增补 `docs/workflows/`（当前树缺此目录）；一句话说明用途 |

**Wave 0a DoD**：主链文档自洽——从 `build-loop` 薄入口出发的每条链，其引用的 skill 要么已存在，要么带 `（planned）`；无悬空 `Phase` 引用；README 目录树与实际一致。

### Wave 0b — 核心新 skill（主链补齐）

| # | 交付 | 验收标准 |
|---|------|----------|
| 6 | ADR 模板 + `skills/architecture-decision-records` | `docs/templates/adr.md`（Status/Context/Options/Decision/Consequences）；skill 说明何时写、`docs/adr/NNN-title.md` 命名；与 clarify-and-plan 步骤 8 交接。**建议早于 #7**（clarify-and-plan 会引用它） |
| 7 | `skills/clarify-and-plan` | 9 阶段硬门（§2.1）；产物落 `docs/design/*` 与 `docs/design/plans/*`；明标「Lane A 内方法，不替代 work-lanes 车道」；含「禁止未批准即实现」门 |
| 8 | `skills/multi-task-protocol` | §2.3 协议；仅覆盖「有书面 plan 的多任务」场景；不碰 remote；可挂 merge-code-review |
| 9 | `skills/systematic-debugging` | Iron Law + 复现→隔离→假设→验证→最小修复+防回归；作为 fix 类默认入口；与 ship-gate 无直接耦合 |
| 10 | `merge-code-review` 收评审附录 | 追加 Appendix（§2.6）；不新建 skill；不改动现有 review 主流程语义 |

**Wave 0b DoD**：fix / feature / 多任务 三条最常用链端到端可走通（clarify → Lane A/B → review → ship-gate → Lane C），且 recommended.md 中对应项已从 `（planned）` 转为可用。

### Wave 1 — 文档与事故（明确高需求）

| # | 交付 | 验收标准 |
|---|------|----------|
| 11 | `skills/document-delivery`（T/P/D）+ 三模板 | 选模式→大纲过审→撰写→导出；模板 `doc-technical.md`/`doc-report-present.md`/`doc-report-design.md`；**不原样搬 vendor 长文**；与 research-case-card 引用规范对齐 |
| 12 | `skills/doc-verify` | 合并 markdown 校验 + broken-links；文档类交付默认收尾门 |
| 13 | `skills/incident-response` + `docs/templates/postmortem.md` | 定级→缓解→沟通→解决→复盘；明标「热修不豁免车道 gate」；根因阶段转 systematic-debugging |

**Wave 1 DoD**：能产出 T/P/D 三型文档并过 doc-verify；事故链（热修→postmortem）文档完整且与 work-lanes/systematic-debugging 交接无矛盾。recommended.md「文档交付 / 事故」菜单项转可用。

### Wave 2 — 前端与 Cursor 原生

| # | 交付 | 验收标准 |
|---|------|----------|
| 14 | `kits/frontend-craft` + `skills/frontend-craft` + `skills/browser-verify` | kit=资产 / skill=薄入口（§2.14）；browser-verify 合并 verifying-in-browser + visual-qa |
| 15 | `skills/parallel-ci-triage` | 拉 Actions 失败并行分修；ship-gate 失败可提示启用（提示，非自动） |
| 16 | `skills/using-git-worktrees`（± hard-problem） | 探测隔离→原生→git worktree；**非默认每提交必用**；触发条件明列 |

### Wave 3 — Review 框架、质量、钩子、库维护

| # | 交付 | 验收标准 |
|---|------|----------|
| 17 | Review 框架落地 | `docs/design/…-review-framework.md` 总图；升级 `code-review` 为「通用/教学/快速」入口；安全轴挂 merge-code-review；**不新增第 4 套并列 review** |
| 18 | security / find-bugs / skill-scanner 轴 | 精简自 Sentry；skill-scanner 可对 `skills/**` 跑；作为轴/门，不独立成 review |
| 19 | `kits/git-hooks`（pre-commit + guardrails） | `install.ps1`/`install.sh` + README；明确「本地 commit 前」vs ship-gate「出站前」两层不互替 |
| 20 | `skills/improve-codebase-architecture` | 架构扫描→选项→可接 clarify grill；架构向，非合并门 |
| 21 | `skills/skill-fit`（含 skill-gardening 节） | 改造已有 skill 贴仓库；合并 gardening 能力（§2.7/§2.8） |

### Wave 4 — 可选

| # | 交付 | 验收标准 |
|---|------|----------|
| 22 | `docs/mcp-presets.md` | 推荐服务器、env 名、最小权限、与 Skill/Kit 分工；不 vendor 源码 |
| 23 | 本机 Superpowers 插件说明 | C 方式；只在文档说明，不进 `skills/` 正文 |

---

## 4. 命名待你拍板（默认已写在上表）

| 默认名 | 备选 |
|--------|------|
| `clarify-and-plan` | `design-clarify` / `align-and-plan` |
| `multi-task-protocol` | `task-agents` / `execute-plan-agents` |
| `skill-fit` | `fit-skills-to-repo` |
| `document-delivery` | `docs-ship` |
| `doc-verify` | 保持拆成两个 skill |
| `frontend-craft` | `frontend-kit` |

---

## 5. 确认记录

| # | 问题 | 决议 |
|---|------|------|
| 1 | 文档模式 | **T + P + D**（2026-07-26 确认） |
| 2 | build-loop | **薄入口**：打开/展示工作流说明，不删除 `skills/build-loop`（2026-07-26 确认） |
| 3 | 开干波次 | 审核完成（§6）；从 **Wave 0a（管道/降级，不新写 skill）** 开工，0a 全绿后进 0b |

## 6. 审核记录

- 审核模型：Claude Opus 4.8（子代理）  
- 审核范围：本决议 vs catalog / work-lanes / ship-gate / build-loop / merge-code-review / docs/README  
- **结论**：**需先做小改后开工**——已在本稿内修订，落地时按修订后的 Wave 0a→0b 顺序即可开 Wave 0（无剩余阻塞性问题）。

**发现与处置（本次已在文内修订）**

| 级别 | 发现 | 处置 |
|------|------|------|
| Critical | 薄 build-loop 的 `recommended.md` 会指向尚未落地的 skill（clarify/multi-task/document-delivery 等分布在 Wave 0b–2），day-one 死链 | §3 拆 Wave 0a/0b；recommended.md **只列已存在项**，其余标 `（planned Wave N）` |
| Important | 降级 build-loop 后，「≥2 方案硬门」与「有界重试 ≤3 次测试环」无明确归属；§2.2 原称「已抽入 multi-task」实为误导（multi-task 只管多任务） | §2.2 增「能力去向表」，把有界重试明文写进 recommended.md；方案门归 clarify-and-plan |
| Important | 降级后 `ship-gate` / catalog 中 `build-loop Phase 5` 等引用悬空，无迁移动作 | 列为 Wave 0a #4 硬性 DoD（grep `build-loop Phase` 归零） |
| Important | `clarify-and-plan` 与 work-lanes Lane A 所有权含糊，§1 箭头易误读为串行外挂 | §1 增「编排层 vs 车道层」说明；§3 #7 明标 Lane A 内方法 |
| Important | `docs/workflows/` 为新目录，`docs/README` 目录树未含，Wave 0 未安排更新 | 列为 Wave 0a #5 |
| Nit | `doc-verify` 合并 vs 拆分在 §2.15 与 §4 表不一致 | §2.15 锁「默认合并」，§4 保留拆分为备选 |
| Nit | `skill-fit` / `skill-gardening` 是否合并在 §2.7、§2.8 反复「可合并」 | 锁默认合并为 skill-fit 内一节 |
| Nit | ADR 路径 `docs/adr/` 与 `docs/decisions/` 两留 | 锁 `docs/adr/`（README 已预留） |
| Nit | `frontend-craft` kit 与 skill 同名、层次未言明 | §2.14 明确 kit=资产 / skill=薄入口 |
| Nit | incident 热修「可跳过 clarify」未重申仍受车道 gate 约束 | §2.12 补「不豁免 Lane C gate」 |
| Nit | ADR skill（#6）被 clarify-and-plan（#7）引用，但原顺序 ADR 在后 | §3 建议 #6 早于 #7 |

**未决（非阻塞，交人拍板）**：§4 命名默认值（`clarify-and-plan` / `multi-task-protocol` / `skill-fit` / `document-delivery` / `frontend-craft`）——已给默认，可直接沿用，无需在 Wave 0 前敲定。
