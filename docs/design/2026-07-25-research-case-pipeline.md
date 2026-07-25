# Design: Track B — research case-card pipeline (学业研究)

Date: 2026-07-25  
Lane: B (local implementation of #15 + #16)  
Status: templates + skill landed locally; ship via Lane C when ready  

## Tracker (already filed — do not recreate)

| Role | Issue |
| --- | --- |
| Umbrella | [#14](https://github.com/Entropy-wz/my-skills/issues/14) `feat(research): case-study pipeline on SearXNG` |
| Child — orchestrator | [#15](https://github.com/Entropy-wz/my-skills/issues/15) `feat(skills): research-case-card …` |
| Child — template | [#16](https://github.com/Entropy-wz/my-skills/issues/16) `docs(research): citation list + case-card template` |

Draft text (historical): `docs/design/drafts/2026-07-25-research-case-pipeline-issue.md`  
Related: `docs/design/2026-07-25-ship-gate-and-research-backlog.md` (Track B stub)

## Goal

Give the agent a **repeatable** path from a research topic to **paste-ready enterprise case cards** + a **citation list**, using only the local `searxng-search` kit (search → fetch → cite). Zero paid Search API.

Primary consumer: competition / course reports (e.g. 高金「企业案例卡」飞书粘贴版结构).

## Non-goals

- Implementing the skill or template in this Lane A slice
- Replacing `searxng-search` or starting Docker from the research skill
- Auto-writing the full competition report (only cards + citations)
- Paid Brave / Tavily / SerpAPI
- Multi-user hosted research service
- Guaranteeing academic-grade plagiarism / copyright clearance (agent must warn: research/cite only)

## Dependencies (already on main)

- `kits/searxng-search`: `tools/search.ps1` (cache, unresponsive engines), `tools/fetch.ps1` (timeouts, batch continue)
- Skill install: `~/.cursor/skills/searxng-search` after `scripts/install.*`

## Architecture

```
User: /research-case-card  (or trigger phrases)
       → confirm topic + constraints (lang, N cards, keywords)
       → searxng-search: search.ps1 (zh-CN/en as needed)
       → agent selects top URLs (prefer official / news / docs)
       → searxng-search: fetch.ps1 top 3–5 per card candidate
       → fill case-card template + citation rows
       → STOP (no push/PR; user pastes into Feishu/report)
```

**Placement:** flat `skills/research-case-card/` (orchestration only).  
Do **not** invent a new kit unless a second consumer needs shared tools beyond SearXNG.

## Output contract (align with 高金案例卡)

Each card (Markdown, Feishu-friendly — headings + bullets, avoid fragile tables):

```markdown
## 卡 N｜<短标题：企业 × 主题>

企业：…
官网：…

业务：…

技术：…

背景：…

报道/材料：
- <来源名>：<URL>
- …

可分析性：★…☆ <一句理由>
```

Citation list (appendix or separate block):

| Field | Rule |
| --- | --- |
| source_title | From search hit or page |
| url | Canonical URL |
| excerpt | ≤ ~400 chars from fetch; quote-friendly |
| retrieved_at | ISO date (UTC or local, labeled) |
| engine | Optional (from search) |

Template file (when #16 ships): e.g. `docs/templates/enterprise-case-card.md`  
+ optional `docs/templates/citation-list.md`  
Skill #15 must link to these paths.

## Skill behavior (#15) — design only

### Triggers

`research-case-card`, `/research-case-card`, `案例卡`, `企业案例检索`, `高金案例`, `搜案例并做成卡`

### Inputs (ask if missing)

1. Topic / direction (e.g. 「数字金融 × 供应链」)
2. Language preference (`zh-CN` default for CN reports)
3. Target card count (default 3, max 5 per run)
4. Optional must-include keywords / exclude domains

### Flow

1. Ensure SearXNG up — if search exits 2, tell user to run `tools/up.ps1`; do not start Docker silently unless user asks.
2. Run 1–3 search queries (broad + refined); prefer `cache=hit` on retries.
3. Rank hits: official site / major media / regulator > random blogs; drop dead/unfetchable later.
4. Fetch top URLs with `fetch.ps1`; continue on single-URL failure.
5. Emit N cards in the template shape + citation appendix.
6. **Stop.** No git/gh. Remind robots/cite policy from fetch skill.

### Guardrails

- No paid API fallback by default.
- No tight search/fetch loops (`MinIntervalSec` / cache).
- Surface `Unresponsive engines` from search footer to the user when results are thin.
- Mark low-evidence cards with lower 可分析性 stars + why.

## Implementation order (later Lane B — not now)

1. **#16** template docs under `docs/templates/` (cheap, unblocks paste consistency)
2. **#15** `skills/research-case-card/SKILL.md` wired to templates + searxng commands
3. Optional: one golden example card in `docs/examples/` (sanitized, no secrets)
4. Lane C: PR with `Fixes #15` / `Fixes #16`, `Refs #14`

## Acceptance (when implemented)

- [ ] Template checked in; skill links it
- [ ] One real topic → ≥3 cards with ≥3 cited URLs total (or honest shortfall)
- [ ] SearXNG down → clear error, no silent Brave
- [ ] No push/PR from the skill
- [ ] Umbrella #14 closable when both children merge

## Risks

| Risk | Mitigation |
| --- | --- |
| Upstream CAPTCHA / empty search | Cache + language switch + unresponsive footer; fewer queries |
| Thin pages / paywalls | Continue-on-error; lower 可分析性; ask user for alternate URL |
| Template drift vs Feishu | Prefer headings+lists (proven in 高金粘贴版) |
| Scope creep into full report writer | Hard stop after cards + citations |

## Deliverables

- [x] Design doc + tracker #14–#16
- [x] `docs/templates/enterprise-case-card.md`
- [x] `docs/templates/citation-list.md`
- [x] `docs/examples/enterprise-case-card-sample.md`
- [x] `skills/research-case-card/SKILL.md`
- [ ] Lane C: PR `Fixes #15` `Fixes #16` `Refs #14`
