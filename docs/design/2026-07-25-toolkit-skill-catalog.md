# 工具库选型目录（Skills / Kits / MCP）

> **用途**：你从本文勾选需要的章节与条目 → 回贴给我 → 再开 Lane A 设计 / Lane B 落地。  
> **现状锚点**（`my-skills` 已有）：  
> `skills/` → work-lanes · build-loop · ship-gate · code-review · merge-code-review · commit-message · hunk-walkthrough · research-case-card  
> `kits/` → searxng-search  
> **检索日期**：2026-07-25（部分内容经本地 SearXNG + GitHub raw 核对）

---

## 如何勾选（复制这段回我）

```text
我选中的章节/条目：
- Ch1 Superpowers: <列出要融入的 skill 名，或「整套对照不 fork」>
- Ch2 awesome / mattpocock: <列表>
- Ch3 三件套: systematic-debugging | incident-response | ADR  →  <进库方式>
- Ch4 前端框架: <要 / 不要 / 改需求：……>
- Ch5 Cursor 原生: <列表>
- Ch6 官方大厂: <列表>
- Ch7 质量安全测试: <列表>
- Ch8 AI 编码工具: <暂缓 / 做某 kit>
- Ch9 MCP: <只要科普 / 要 mcp-presets kit / 要装哪些>
```

**融入方式约定（全文通用）**

| 代号 | 含义 |
|------|------|
| **A 对照** | 只读对方文档，把要点写进我们已有 skill 的一节（不新增 skill） |
| **B 精简进库** | 拷贝/改写为 `skills/<name>/`，对齐我们的 frontmatter / 触发语 / 与 work-lanes 交接 |
| **C 整包引用** | 本机用官方 plugin / marketplace 安装，库内只写「推荐安装」说明 |
| **D Kit** | `kits/<name>/`：脚本 + Docker/CLI + 可选薄 skill 当入口 |
| **E 暂缓** | 场景未到，目录里留坑 |

---

# Ch1 · Superpowers 全部 Skills

来源：[obra/superpowers](https://github.com/obra/superpowers)（14 个 composable skills + 启动引导）

整体定位：一套「先设计 → 再计划 → TDD → 子代理执行 → 验证 → 收尾」的**方法论框架**，不是零散技巧。

### 1.1 全表（介绍 + 与我们的重叠）

| Skill | 一句话 | 核心约束 | 与我们 | 建议 |
|-------|--------|----------|--------|------|
| **using-superpowers** | 会话启动：有技能就先调用 | 适用概率 ≥1% 也必须 invoke | 我们靠 `disable-model-invocation` + 触发语，风格相反 | **C 或 E**（整包启用才有意义；单独进库会打架） |
| **brainstorming** | 创意工作前必做：澄清 → 方案分段过审 → 才允许写代码 | HARD-GATE：未批准设计禁止实现 | ≈ `work-lanes` Lane A + `build-loop` Phase1–3 | **A**：把「硬门」写进 work-lanes/build-loop；或 **C** |
| **writing-plans** | 规格就绪后写「零上下文也能执行」的咬口任务计划 | YAGNI / TDD / 高频 commit；默认写到 `docs/superpowers/plans/` | 我们有 `docs/design/plans/` | **A 或 B**：计划模板对齐我们路径即可 |
| **executing-plans** | 在**新会话**按计划执行并设检查点 | 有子代理时更推荐 subagent-driven | ≈ Lane B + build-loop | **A** |
| **subagent-driven-development** | 当前会话：每任务新子代理 + 任务后 review + 末尾全分支 review | 不问「要继续吗」；卡住才停 | Cursor Task 子代理可落地；我们缺「强制任务后 review」 | **A→B**：抽一条「多任务执行协议」进 build-loop |
| **dispatching-parallel-agents** | ≥2 个无共享状态任务时并行派代理 | 一问题域一代理；不继承父会话历史 | 可补强大仓探索 / 多测失败 | **B**（薄 skill）或 **A** |
| **using-git-worktrees** | 功能开工前保证隔离工作区 | 先探测已有隔离 → 原生工具 → git worktree | Cursor best-of-n / worktree 相关；我们未固化 | **B 可选**（和 best-of-n 一起） |
| **test-driven-development** | 先测再写；没见红就不算测对了 | Iron Law 级纪律 | build-loop 有测后修，但非强制红绿 | **A**：Lane B / build-loop 增加「可选 TDD 模式」 |
| **systematic-debugging** | 任何 bug/失败/异常行为：先根因再改 | **NO FIXES WITHOUT ROOT CAUSE** | build-loop bug 路径偏「复现→修」；缺强制根因门 | **B（强烈）** — 见 Ch3 |
| **verification-before-completion** | 宣称完成/通过前必须有新鲜验证证据 | **NO COMPLETION CLAIMS WITHOUT EVIDENCE** | ≈ ship-gate Verification + work-lanes gate | **A**：已基本覆盖；可抄 Iron Law 措辞 |
| **requesting-code-review** | 重大功能后 / 合并前派只读 reviewer 子代理 | 早审、勤审；给精确上下文 | ≈ merge-code-review / code-review | **A**（已有） |
| **receiving-code-review** | 收到评审：先核实再改，禁止表演式同意 | 技术正确 > 社交舒适 | 我们缺「收评审」协议 | **B 薄** 或写进 merge-code-review 附录 |
| **finishing-a-development-branch** | 测绿后：验环境 → 给出合并/PR/清理选项 → 执行 | 测红不进菜单 | ≈ ship-gate → work-lanes Lane C | **A**（已有编排） |
| **writing-skills** | 用 TDD 思想写 skill：先看代理无 skill 时失败 | 依赖 TDD skill | 维护工具库时有用 | **C 或 B**（我们写 skill 时的参考） |

### 1.2 融入策略（推荐默认）

1. **不要整仓 fork 进 `skills/`**（与我们「显式触发 / disable-model-invocation」冲突，且重复造轮）。  
2. **本机可 C：Cursor `/add-plugin superpowers`**，当「重方法论模式」开关。  
3. **库内只做 A/B 吸收**：  
   - 根因门 → 独立 `systematic-debugging`（Ch3）  
   - 证据门 → 已有 ship-gate，补一句 Iron Law  
   - 设计硬门 → work-lanes Lane A / build-loop 文案  
   - 并行子代理 → 可选薄 skill  

**你要勾的**：`□ 仅 C 本机插件` `□ A 吸收铁律到现有 skill` `□ B 下列独立 skill：________`

---

# Ch2 · Awesome Cursor Skills + Matt Pocock Skills

## 2.1 Awesome Cursor Skills（目录级）

来源：[spencerpauly/awesome-cursor-skills](https://github.com/spencerpauly/awesome-cursor-skills)（~616★）

这是**策展清单**（很多 `resources/*.md` + 外链到 Anthropic / Vercel / Sentry / Matt 等），不是单一框架。适合当「货架」。

### 分类速览（按清单结构）

| 类 | 代表条目 | 对我们的价值 |
|----|----------|--------------|
| **Cursor-Native** | browser QA、并行 explore、CI triage、hooks/rules 建议、best-of-n… | **高** — 见 Ch5 |
| Analytics / Auth / Stripe | PostHog、Auth.js、Stripe | 业务项目需要再进，不宜堆进通用库 |
| Testing | Playwright、writing-tests、api-smoke、mattpocock-tdd | 见 Ch7 |
| Workflow | babysitting-pr、creating-PR、commit、incident、systematic-debugging | 部分与我们重复；incident/ADR/debug 见 Ch3 |
| Infra | Terraform、K8s | 有运维再进 |
| Code Quality & Security | reviewing-code、auditing-security、Sentry 系列 | 见 Ch7 |
| Frontend & UI | frontend-design、Vercel React、shadcn | 见 Ch4 / Ch6 |
| Planning | Matt grill / PRD / architecture、ADR、mcp-builder | 高 |
| Documentation | OpenAPI、Anthropic 文档/Office | 按交付物进 |
| Plugins（Marketplace） | Figma、Linear、Sentry、Vercel… | 见 Ch9 MCP |

**融入原则**：从 awesome **cherry-pick** → B 精简进库；不要 submodule 整个 awesome。

## 2.2 Matt Pocock Skills（全量工程向）

来源：[mattpocock/skills](https://github.com/mattpocock/skills)

偏「产品工程操作系统」：路由、质询、规格、票据、实现、架构加深。

### Engineering

| Skill | 介绍 | 建议 |
|-------|------|------|
| **ask-matt** | 路由：当前情况该用哪条 skill/flow | E 或 C（整包用才有意义） |
| **grill-me** / **grilling** / **grill-with-docs** | 犀利追问压实方案；with-docs 边问边产 ADR/术语表 | **B：grill-me**（与 Lane A 互补）；grill-with-docs 可替代 ADR 手写 |
| **to-spec** | 把已有对话收成规格并推到 tracker | 有固定 issue 流再 B |
| **to-tickets** | 规格拆成 tracer-bullet 票据（含阻塞边） | 大项目时 B |
| **wayfinder** | 超大工作：用 decision tickets 当地图 | E（重） |
| **triage** | 外来 issue/PR 状态机：分类→核实→grill→agent-ready brief | 与 work-lanes「出站」互补；若你做开源维护 → **B 值得** |
| **implement** | 按 spec/tickets 实现 | ≈ build-loop；**A** |
| **tdd** | 红绿重构 / 集成测优先 | **A 或 B** |
| **code-review** | 相对固定点：Standards + Spec 双轴 | 与我们 review 重叠 → **A**（可吸收「双轴」） |
| **diagnosing-bugs** | 难 bug / 性能回归诊断环 | 与 systematic-debugging 近亲 → 二选一或合并 |
| **improve-codebase-architecture** | 扫描加深机会 → HTML 报告 → grill | 架构整顿时 **B** |
| **codebase-design** | 深模块词汇表（接口/缝/可测性） | 架构向 **A/B** |
| **domain-modeling** | 领域语言 / 决策记录 | 与 ADR 近 → 可和 Ch3 ADR 合并 |
| **prototype** | 一次性原型回答设计问题 | Lane A/B 尖峰时有用 **B 可选** |
| **research** | 高可信源调研并落盘 Markdown | 与 **research-case-card + searxng** 重叠 → **A** |
| **resolving-merge-conflicts** | 解决进行中的 merge/rebase | 薄 **B 可选** |
| **setup-matt-pocock-skills** | 一次性配置 tracker/标签/领域文档布局 | 仅当你整包采用 Matt 流 |

### Productivity / Misc（摘）

| Skill | 建议 |
|-------|------|
| **handoff** | 会话交接文档 — **B 可选**（多代理/多日任务） |
| **writing-great-skills** | 写 skill 的词汇与原则 — 维护库时 **A** |
| **setup-pre-commit** / **git-guardrails-*** | 钩子与护栏 — 按编辑器选；我们已有 commit 卫生 |

**Matt 默认短名单**：`grill-me` ·（可选）`tdd` ·（可选）`improve-codebase-architecture` ·（开源维护才）`triage`

**你要勾的**：`□ grill-me` `□ tdd` `□ improve-architecture` `□ triage` `□ handoff` `□ 其他：__`

---

# Ch3 · 三件套详尽：debugging / incident / ADR

## 3.1 systematic-debugging

### 有两个「血统」

| 版本 | 来源 | 气质 |
|------|------|------|
| **Superpowers** | obra | 铁律：「没有根因调查禁止改代码」；流程更硬、更代理纪律 |
| **Awesome-cursor** | spencerpauly resources | 实践清单：复现 → 隔离（二分/bisect/分层）→ 假设 → 最小验证 → 修并写防回归测 |

Awesome 版步骤摘要：

1. **Reproduce** — 步骤、期望/实际、是否稳定、环境  
2. **Isolate** — 代码二分 / `git bisect` / 前后端·DB·API·组件分层  
3. **Hypothesize** — 可证伪的「因为 Y 所以 X」  
4. **Test hypothesis** — 最小 log/断点/单测  
5. **Fix & verify** — 最小修复 + 原复现路径 + 回归 + 补测  

附：场景→工具表（bisect / 日志 / 环境差 / 竞态等）与常见 bug 模式。

### 怎么融入我们（推荐）

| 选项 | 做法 |
|------|------|
| **推荐 B** | 新增 `skills/systematic-debugging/`：正文以 Awesome 清单为骨架，开头加 Superpowers Iron Law；触发语「debug systematically」「系统排障」 |
| **挂钩** | `build-loop`：当 mode=fix 时 **必须先走** 本 skill（或内联同一铁律），禁止直接猜补丁 |
| **与 ship-gate** | 无关直接耦合；修完仍走 build-loop → review → ship-gate |
| **勿** | 同时原样进库两个同名 skill |

勾选：`□ B 独立 skill` `□ 只把铁律写进 build-loop（A）`

---

## 3.2 incident-response

### 它是什么

Awesome 版：生产事故手册 —— **定级 → 缓解 → 沟通 → 解决 → 48h 内无责备事后复盘**。

- SEV1/SEV2… 与响应时效  
- 缓解：回滚、feature flag、扩容、故障转移、限流  
- 沟通：事故频道、角色（IC/沟通/工程）、对外 status  
- Postmortem 模板：时间线、根因、做得好/不好、Action Items  

### 怎么融入我们

| 判断 | 建议 |
|------|------|
| 你主要是个人工具库、无 on-call | **E 暂缓** — 文档里保留本节即可 |
| 有线上服务 / 团队值班 | **B** → `skills/incident-response/`，模板放到 `docs/templates/postmortem.md` |
| 与 systematic-debugging | 事故里「缓解」优先于根因；根因阶段再调 debugging skill |
| 与 work-lanes | 事故热修常走 Lane B 本地 → 紧急 Lane C；可在 skill 里写「热修免走完整 design，但必须事后补 ADR/postmortem」 |

勾选：`□ E 暂缓` `□ B 进库 + 模板` `□ 只要 postmortem 模板不要 skill`

---

## 3.3 architecture-decision-records（ADR）

### 它是什么

在 `docs/decisions/`（或 `adr/`）写短决策记录：Status / Context / Options / Decision / Consequences。  
**不是**完整设计文档 —— 只固化「为什么选 X」。

我们的 `docs/README.md` 已预留 `docs/adr/`。

### 怎么融入我们

| 选项 | 做法 |
|------|------|
| **推荐 B 薄 skill** | `skills/architecture-decision-records/` + `docs/templates/adr.md` + 命名 `NNN-title.md` |
| **挂钩 Lane A** | work-lanes：设计里出现「难逆、多处影响、多方案权衡」→ 提醒写 ADR（可与 design doc 同 PR/同提交） |
| **挂钩 Matt** | 若进 `grill-with-docs`，ADR 可由质询过程自动产；可少做一个独立 skill |
| **与 research-case-card** | 调研卡解决「外部证据」；ADR 解决「我们拍板」——互补 |

勾选：`□ B skill+模板` `□ 只要模板` `□ 用 grill-with-docs 代替`

---

# Ch4 · 前端：不要只做 Skill，做「框架」（Kit + Skills）

目标：一个可安装的 **前端设计与验收框架**，而不是单文件文案。

## 4.1 推荐形态：`kits/frontend-craft`（名可改）

```
kits/frontend-craft/
  README.md                 # 何时用、安装、与 Cursor Browser 关系
  tools/
    smoke-ui.ps1            # 起 dev server、打 URL、可选截图目录约定
    a11y-checklist.md       # 或调用 axe/playwright 脚本
  templates/
    ui-review.md            # 验收记录：视口 / 主题 / 无障碍 / 网络
  # 可选：Playwright 最小脚手架（package 或脚本说明）
skills/frontend-craft/      # 薄入口 skill：编排下面「能力层」
```

## 4.2 能力层（组合，而不是一个万能 SKILL）

| 层 | 内容来源 | 作用 |
|----|----------|------|
| **设计品味** | Anthropic `frontend-design`（+ 可选 brand-guidelines） | 避免「AI 紫白渐变/卡片堆」；定视觉方向 |
| **工程规范** | Vercel `react-best-practices` · `web-design-guidelines` · `composition-patterns` | 性能、a11y、RSC/组合 |
| **组件栈** | shadcn skill（若你用 shadcn） | 增改组件姿势 |
| **运行时验收** | Cursor-Native：`verifying-in-browser` · `visual-qa-testing` · `responsive-testing` · `accessibility-auditing` · `dark-mode-testing` | 真浏览器证据 |
| **回归资产** | Playwright（kit 脚本）· `recording-browser-flow-as-test` | 把手工点检变成测试 |

## 4.3 和现有库的交接

```
Lane A: frontend-craft 设计约束写进 design doc
    → Lane B: 实现（可挂 Vercel React 规则）
    → 实现期测试/类型检查（见 `docs/workflows/recommended.md` 有界重试 ≤3）
    → frontend-craft 验收: Browser 截图 + checklist（证据进对话/文档）
    → ship-gate → Lane C
```

## 4.4 决策题（请勾）

- `□ 要 kits/frontend-craft（脚本+模板+入口 skill）`  
- `□ 只要 skills，不要 Playwright/脚本`  
- `□ 技术栈锁定：React/Next / Vue / 纯静态 / 其他：__`  
- `□ 必须兼容我们前端 design 规则（反通用 AI 审美）——写入 kit README`

---

# Ch5 · Cursor 原生能力 Skills — 设计方案

来源：awesome「Cursor-Native」子集。原则：**进库要能接到我们的编排**，不进「好玩但无挂钩」的。

## 5.1 推荐进库包（按优先级）

| 优先级 | Skill（可改名） | 作用 | 融入点 |
|--------|-----------------|------|--------|
| P0 | **verifying-in-browser** | 起服务、侧栏打开、看渲染/控制台/网络 | `frontend-craft` + build-loop 后可选门 |
| P0 | **visual-qa-testing** | 改完截图 + console/network 审计 | 同上 |
| P0 | **parallel-ci-triage** | 拉 Actions 失败日志，分给并行子代理修 | **ship-gate 失败分支** 或独立触发 |
| P0 | **suggesting-cursor-rules** | 反复纠正同一约定 → 建议写成 rule | 工具库维护 / 任意项目 |
| P0 | **building-skills-from-patterns** | 重复多步流程 → 新 SKILL.md | 元能力；写进「维护 my-skills」 |
| P1 | **responsive-testing** / **dark-mode-testing** / **accessibility-auditing** | 多视口 / 主题 / aria | frontend-craft |
| P1 | **grinding-until-pass** | 修到测过/构建过 | 与 build-loop 有界重试 **合并**，勿双轨 |
| P1 | **best-of-n-solving** + **using-git-worktrees** | 难问题多方案 | 独立「难题模式」；Lane B |
| P1 | **parallel-exploring** / **codebase-onboarding** | 大仓并行探查 | 接手陌生仓 |
| P2 | **suggesting-cursor-hooks** | 反复同一检查 → hooks.json | 有稳定门禁后 |
| P2 | **monitoring-terminal-errors** / **detecting-port-conflicts** / **finding-dev-server-url** | 终端/端口运维向 | 可合成一个 `dev-server-ops` |
| P2 | **parallel-code-review** | 安全/性能/正确/可读四代理 | 与 merge-code-review：**吸收结构或 E** |
| P2 | **babysitting-pr** | 盯 PR | 与 Cursor babysit 重叠 → 倾向 E |
| P2 | **screenshotting-changelog** / **comparing-branches-visually** | 视觉 PR 描述 | 前端多再进 |
| P2 | **saving-workspace-context** | 跨会话持久化 | 与 research-case-card 分工后可进 |
| P2 | **auto-type-checking** | 编辑后 tsc | 用 hooks 比 skill 更合适 |

## 5.2 建议落地形态

```
skills/
  browser-verify/          # 合并 verifying + visual-qa（一个入口）
  parallel-ci-triage/
  skill-gardening/         # 合并 suggesting-rules + building-skills-from-patterns
  hard-problem-mode/       # 可选：best-of-n + worktrees
kits/frontend-craft/       # Ch4；原生 browser skills 当运行时层
```

**与 ship-gate**：`run-gates` 非零 → 可选提示「是否启用 parallel-ci-triage」。  
**与 work-lanes**：原生 skills 默认 Lane B；不自动 Lane C。

勾选：`□ P0 全要` `□ 只要 browser-verify + ci-triage` `□ 加上 hard-problem-mode` `□ 自定义：__`

---

# Ch6 · 官方 / 大厂 Skills（按栈）+ 更多举例

## 6.1 按栈默认（此前共识）

| 栈/场景 | 采纳 | 方式 |
|---------|------|------|
| 文档交付（PDF/Word/PPT/Excel） | Anthropic `pdf` `docx` `pptx` `xlsx` | **B 或 C**（document-skills 插件） |
| 前端 UI | `frontend-design` + Vercel 三件套 | 进 Ch4 框架 |
| Web 测试 | Anthropic `webapp-testing` | 进 frontend-craft 或 Ch7 |
| 自建 MCP | Anthropic `mcp-builder` | **B**（见 Ch9） |
| 长文共创 | `doc-coauthoring` | 可选 B |
| React/Next | Vercel `react-best-practices` 等 | **B**（vendoring 规则文件） |
| 质量品牌 | Sentry `security-review` `find-bugs` `skill-scanner` | **B 精选** |

## 6.2 更多「大厂/官方有保障」举例

| 来源 | 代表 | 保障感 | 进库建议 |
|------|------|--------|----------|
| **Anthropic** [anthropics/skills](https://github.com/anthropics/skills) | frontend-design, mcp-builder, document-*, skill-creator, theme-factory, web-artifacts-builder | 官方样板 | 文档/前端/MCP 按需 B；creative 类（algorithmic-art 等）多数 E |
| **Vercel** [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | react-best-practices, web-design-guidelines, composition-patterns, react-view-transitions, deploy-to-vercel | 前端事实标准向 | React 栈 **B**；deploy 类用官方插件即可 |
| **Sentry** [getsentry/skills](https://github.com/getsentry/skills) | security-review, find-bugs, code-simplifier, skill-scanner, gha-security-review, triage-frontend-issues | 工程/安全向强 | **skill-scanner + security-review** 优先；commit/pr-writer 与我们重复则跳过 |
| **PostHog** skills | llm-analytics, migrations, feature flags | 产品分析官方 | 用 PostHog 再进 |
| **Stripe** Cursor plugin | stripe-best-practices | 支付官方 | 做支付再 C |
| **shadcn** | 官方 skill 文档 | 组件生态官方 | 用 shadcn 再 C/B |
| **Notion** | Notion Skills for Claude（Anthropic 伙伴页） | 官方伙伴 | 用 Notion 再 C |
| **Cursor Marketplace** | Figma / Linear / Datadog / Firebase / Shopify / dbt | 一阶集成 | **C + MCP**，一般不 vendor 进 git |

### 额外可关注（保障略低但仍主流）

- **Anton Babenko terraform-skill** — IaC 专家个人品牌，Terraform 场景  
- **SkillsMP / skills.sh** — 目录站，**不是**保障来源；只当搜索  

勾选大厂包：`□ Anthropic documents` `□ Anthropic frontend+webapp-testing` `□ mcp-builder` `□ Vercel React 包` `□ Sentry security+scanner` `□ 其他：__`

---

# Ch7 · 质量 / 安全 / 测试 — 规划

## 7.1 目标能力图

```
实现中                合并前                 库自举
build-loop 测试  ←→  ship-gate gates  ←→  skill-scanner（扫我们自己的 skills）
       ↓                    ↓
systematic-debugging   security-review / find-bugs
       ↓
api-smoke / e2e（项目级）
```

## 7.2 推荐清单

| 项 | 来源 | 方式 | 说明 |
|----|------|------|------|
| **systematic-debugging** | Ch3 | B | 质量的「过程门」 |
| **security-review** | Sentry 或 awesome auditing-security | B 精简 | 合并前可选；可挂 merge-code-review「安全轴」 |
| **find-bugs** | Sentry | B 或 A | 本地 branch diff 扫 |
| **skill-scanner** | Sentry | **B 强烈** | 防 skill 投毒/提示注入；CI 可对 `skills/**` 跑 |
| **api-smoke-testing** | awesome | 项目 kit 或 B | 有 HTTP API 时 |
| **adding-e2e-tests** / Playwright | awesome + Ch4 kit | D | 前端框架的一部分 |
| **mattpocock-tdd** / Superpowers TDD | Matt / obra | A | 写入 build-loop「TDD 模式」而非第四套流程 |
| **gha-security-review** | Sentry | 有 Actions 加固需求再 B | |
| **verifying-markdown / fixing-broken-links** | awesome | 文档多再 B | |

## 7.3 与现有 skill 的边界

| 已有 | 新东西别重复做 |
|------|----------------|
| code-review / merge-code-review | 可增加「安全轴」调用 security-review，不新造第四个 review |
| ship-gate / run-gates | 门禁执行器；security 可以是其中一道 gate 脚本 |
| commit-message | 跳过 Sentry commit skill |

勾选：`□ debugging` `□ security-review` `□ find-bugs` `□ skill-scanner` `□ api-smoke` `□ e2e/Playwright` `□ TDD 模式写入 build-loop`

---

# Ch8 · AI 编码工具（Aider / Continue / Cline…）对我们有用吗？

**结论先说：你们主战 Cursor 的前提下，多数「第二 IDE Agent」不必进库；价值是可选旁路，不是主链。**

| 工具 | 典型强项 | 对「只用 Cursor」的你 |
|------|----------|----------------------|
| **Cursor** | 项目上下文、Agent、Browser、MCP、Skills | 主链，已覆盖 |
| **Claude Code** | 终端代理、插件市场、Superpowers 一流支持 | 若你有时用 CC → 用 **C** 装插件即可，不必进 my-skills |
| **Aider** | 终端、多文件、自动 git commit、可挂本地/任意模型 | **唯一较值得想的 kit**：无 GUI 批处理、CI 里改代码、或 Cursor 额度/故障时的备用 |
| **Continue / Cline / Roo** | VS Code 开源 Agent | 你已在 Cursor → **边际收益低** |
| **Copilot / Windsurf / Codex** | 另一套 IDE/配额 | 工作流分叉成本高 → **不建议进库** |
| **LangGraph / CrewAI…** | 产品内多代理编排 | 那是应用架构，不是个人工具库 skill |

### 我的想法（可反对）

1. **my-skills 继续押注 Cursor Skills + 少量 Kits（SearXNG、frontend-craft、run-gates）** —— 与编辑器同源，安装/发现成本最低。  
2. **不要**为「榜单热度」做 Aider/Continue 包装，除非你亲自出现每周 ≥1 次的真实场景。  
3. 若以后要「无 Cursor 的自动改码」，再开 Lane A 设计 `kits/aider-bridge`（输入：repo 路径 + 任务文件；输出：commit），且仍受 work-lanes 约束。  

勾选：`□ 同意暂缓` `□ 要调研 Aider kit` `□ 我其实也用 Claude Code，需要双运行时说明`

---

# Ch9 · MCP / 插件是什么？（科普 + 和 Skills 的分工）

## 9.1 一句话

| 概念 | 是什么 | 类比 |
|------|--------|------|
| **Skill** | 给模型看的「标准作业程序」（Markdown 说明） | 员工手册 |
| **MCP Server** | 给模型用的「工具插座」（查 DB、读 Figma、发 Slack…） | 电动工具本身 |
| **Cursor Plugin / Marketplace** | 一键打包：常含 MCP + 若干 Skills + 配置 | 品牌工具箱套装 |

模型**只读 Skill 不会真的连上 Figma**；要连外部系统，需要 MCP（或 Cursor 内置 Browser 等工具）。

## 9.2 你已经在用的例子

- **cursor-app-control**（若启用）：切工作区、建项目等 — 这就是 MCP。  
- **SearXNG**：我们做成了 **Kit（脚本+Docker）**，不一定非 MCP；也可以再包一层 MCP 让 Agent 直接 `search` 工具化。  
- Agent 里的 **Shell / Read / GitHub `gh`**：有的是内置工具，有的可换成 MCP。

## 9.3 什么时候该加 MCP？

| 需要 | 示例 | 建议 |
|------|------|------|
| 反复读外部 SaaS | Linear 票、Slack 线程、Datadog 日志、Figma 节点 | Marketplace 装官方插件（**C**） |
| 内部系统 | 公司 API、私有文档库 | 自建 MCP（Anthropic **mcp-builder** + 我们的 kit 规范） |
| 纯本地命令 | git、pytest、docker | **不必 MCP**，Skill + Shell 足够 |
| 只要改变行为/流程 | 车道、gate、review | **只要 Skill** |

## 9.4 和 my-skills 的推荐分工

```
skills/     → 流程与标准（我们的主战场）
kits/       → 可运行依赖（Docker、脚本、二进制包装）
MCP         → 默认「本机 Cursor 设置里装」，仓库只维护：
              docs/mcp-presets.md 或 kits/mcp-presets/（可选）
              列出：推荐服务器、env 变量名、最小权限、是否要 OAuth
```

**安全提醒**：MCP 能读票、写频道、碰云资源 —— 最小权限、能只读则只读；来路不明的第三方 MCP 等同安装不明程序。Sentry **skill-scanner** 扫的是 Skill 文本风险；MCP 还要看其代码与权限范围。

## 9.5 常见官方插件（了解即可）

Figma · Linear · Slack · Datadog · Sentry · Vercel · Stripe · Firebase · Shopify · dbt  

勾选：`□ 只要本章科普` `□ 写 mcp-presets 文档` `□ 做 kits/mcp-presets` `□ 用 mcp-builder 教程进库` `□ 我想先装的插件：__`

---

# 附录 A · 与「一条龙」主链的对照

```
意向
  → [可选 grill-me]
  → work-lanes Lane A（设计；可选 ADR）
  → [可选 writing-plans 吸收]
  → Lane B + build-loop
       ├ fix → systematic-debugging
       ├ feature → 可选 TDD 模式
       └ 前端 → frontend-craft（设计规则 + browser 验收）
  → merge-code-review（可选 security 轴）
  → ship-gate（gates；失败可 parallel-ci-triage）
  → Lane C 出站
```

Superpowers 整包 ≈ 上图的「严格模式」；我们是「显式编排 + 可开关模块」。

---

# 附录 B · 我建议的「第一波吸收」（若你懒得逐条勾）

仅建议，可整段否决：

1. **B** `systematic-debugging`（挂钩 build-loop fix）  
2. **B** ADR 模板 + 薄 skill（挂钩 Lane A）  
3. **D+B** `frontend-craft` 框架（Anthropic design + Vercel 规则 + browser-verify）  
4. **B** `browser-verify` · `parallel-ci-triage` · `skill-gardening`  
5. **B** Sentry `skill-scanner`（+ 可选 security-review）  
6. **B** Matt `grill-me`  
7. **C** 本机可选 Superpowers 插件；库内 A 吸收 verification 铁律  
8. **E** incident-response、Aider、Continue  
9. **文档** Ch9 MCP 科普 + 按需 `mcp-presets.md`  

---

**下一步**：把文首「如何勾选」填好发我；或直接说「按附录 B」。我再按 work-lanes 拆 Lane A 设计议题 / 实现顺序。
