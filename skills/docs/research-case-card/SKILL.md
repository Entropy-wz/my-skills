---
name: research-case-card
description: Build paste-ready enterprise case cards and a citation list from a research topic via local SearXNG search+fetch only. Never use paid Search APIs (Brave/Tavily/SerpAPI). Use for competition/course case cards, 高金-style Feishu paste blocks, and CN/EN case study lookup. Trigger phrases — "research-case-card", "/research-case-card", "案例卡", "企业案例检索", "高金案例", "搜案例并做成卡".
---

# Research Case Card

Orchestrates **local** `searxng-search` (search → fetch → cite) into Feishu-friendly **企业案例卡** + **引用清单**.  
Does **not** push, open PRs, or call paid Brave/Tavily/SerpAPI.

Issues: umbrella [#14](https://github.com/Entropy-wz/my-skills/issues/14), skill [#15](https://github.com/Entropy-wz/my-skills/issues/15), templates [#16](https://github.com/Entropy-wz/my-skills/issues/16).  
More detail: [reference.md](reference.md).

## Templates (required — skill-local)

Resolve paths **from this skill directory** (works after install into `~/.cursor/skills/research-case-card/`):

| File | Role |
| --- | --- |
| [`templates/enterprise-case-card.md`](templates/enterprise-case-card.md) | Per-card shape |
| [`templates/citation-list.md`](templates/citation-list.md) | Citation **paste block only** |
| [`examples/enterprise-case-card-sample.md`](examples/enterprise-case-card-sample.md) | Shape-only sample |

If a link fails, ask for `MY_SKILLS_ROOT` and read the same files under `skills/docs/research-case-card/` in the checkout — do **not** invent a card shape.

Emit headings + bullets; avoid fragile tables in user-facing paste.

## When to use

- User wants **案例卡 / 企业案例 / 高金粘贴版** structure from web sources
- Local SearXNG kit is (or can be) available
- Prefer this over ad-hoc search paste when consistency matters

## When not

- Pure coding / local-repo questions → no web
- User asks to ship/push → `work-lanes`
- User demands paid search → refuse paid APIs; offer to wait for SearXNG / change query only

## Prerequisites

1. `searxng-search` installed (`scripts/install.*` from my-skills)
2. Docker + instance up when live search is needed:

```powershell
# From ~/.cursor/skills/searxng-search (or kits/searxng-search):
powershell -NoProfile -ExecutionPolicy Bypass -File tools/up.ps1
```

Optional: `pip install trafilatura` for better `fetch.ps1` extraction.

## Resolve searxng tools

Prefer, in order:

1. `~/.cursor/skills/searxng-search/tools/search.ps1` (and sibling `fetch.ps1`)
2. `$env:MY_SKILLS_ROOT/kits/searxng-search/tools/…`
3. Ask the user for their my-skills / skill install path

## Inputs (ask if missing)

1. **Topic / direction** (e.g. `数字金融 × 供应链`)
2. **Language** — default `zh-CN` for CN reports; use `en` when needed (pass through to `-Language`)
3. **Card count** — default 3, max 5 per run
4. Optional must-include keywords / exclude domains — apply when ranking hits

## Flow

### 1. Confirm inputs

Restate topic, N, language (`<lang>`). Do not start Docker unless the user asks.

### 2. Search (1–3 queries)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <searxng>/tools/search.ps1 -Query "<q>" -Language <lang> -Count 8
```

Replace `<lang>` with the confirmed value (`zh-CN` or `en`), never hardcode against the user's choice.

- Broad query, then refined (enterprise names, 「案例」「白皮书」, must-include keywords)
- Prefer `cache=hit` on repeat; use `-Refresh` only for breaking news
- If exit **2** (unreachable): tell user to run `tools/up.ps1`; **STOP**. **Never** fall back to Brave/Tavily/SerpAPI or any paid Search API.
- Paste/search footer **Unresponsive engines** when results are thin

### 3. Rank hits

Prefer: official site / major media / regulator / company IR > random blogs.  
Drop exclude-domain matches and obvious junk; note weak evidence early.

### 4. Fetch bodies

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <searxng>/tools/fetch.ps1 -Url "https://a.example,https://b.example" -MaxChars 4000
```

- Top 3–5 URLs per promising card; continue on single-URL failure
- Respect fetch policy (research/cite; no tight loops)

### 5. Emit cards + citations

- Fill **N** card blocks from `templates/enterprise-case-card.md` (card section only; batch wrapper optional)
- Append **only** the `## 引用清单` paste block from `templates/citation-list.md` — do **not** paste Field rules or other author notes
- `retrieved_at` labeled with timezone
- Set 可分析性 stars honestly; never invent metrics
- If you cannot honestly produce ≥3 cited URLs total, say so (shortfall) and emit fewer cards rather than fabricating sources

### 6. STOP

- No `git push` / `gh pr` / `gh issue`
- User pastes into Feishu / report docs
- Remind: research/citation use; fetch does not honor robots.txt at scale

## Progress checklist

```
- [ ] Inputs confirmed (topic, lang, N; keywords/excludes if any)
- [ ] Skill-local templates readable
- [ ] searxng tools resolved
- [ ] Search run with -Language <lang>; STOP on exit 2 (no paid API)
- [ ] URLs ranked; fetch completed (continue-on-error)
- [ ] N case cards emitted per template
- [ ] Citation paste block only emitted
- [ ] Stopped — no remote actions
```

## Guardrails

- **Never** use paid Search APIs (Brave / Tavily / SerpAPI / etc.), including after SearXNG failure
- No silent Docker start
- No full report writer — **cards + citations only**
- No fabricated excerpts or URLs
- Rate-limit aware: reuse search cache; avoid hammering fetch

## Example

User: `/research-case-card 数字金融 供应链 做 3 张案例卡`（或自然语言「做几张高金企业案例卡」）

Agent: confirm (lang=zh-CN) → `search.ps1 -Language zh-CN` → select URLs → `fetch.ps1` → emit 3 cards + `## 引用清单` only → stop.
