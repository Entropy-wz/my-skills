# Design: SearXNG kit Phase 2 (short iteration)

Date: 2026-07-25  
Lane: A (design-only)  
Depends on: MVP shipped in [#2](https://github.com/Entropy-wz/my-skills/issues/2) / PR #3  

## Goal

Make `kits/searxng-search` usable for **heavier research** (高金案例检索等)：在免费元搜索之上增加「可读正文」与「重复查询降压」，并改善中文命中与上游限流时的可操作性。仍不引入付费 Search API。

## Out of scope

- Replacing SearXNG with Brave/Tavily/SerpAPI
- Public exposure of the instance (stay on `127.0.0.1`)
- Multi-user auth / SaaS packaging
- Full “deep research agent” product (可另开 kit)

## Proposed slices (separate child issues under a new umbrella)

### P2-A — Page fetch for top-N results

**Why:** Snippets alone are thin for case studies / 研报引用。  

**What:**
- `tools/fetch.ps1` (or Python) that takes URLs from `search.ps1` output / JSON
- Extract main text via `trafilatura` (preferred) with a small fallback
- Respect: timeout, max bytes, optional robots ignore only for explicit user research (document policy)
- Skill update: when user asks for “深度/正文/引用”，search → fetch top 3–5

**Acceptance:**
- [ ] Given 3 URLs, returns plain-text/markdown excerpts with source URL
- [ ] Hard timeout per URL (e.g. 10s); failures do not abort the batch
- [ ] Documented “research use / cite sources” note in kit README

**Effort:** S–M  

### P2-B — Local result cache

**Why:** 降低上游 CAPTCHA/429；重复 query 便宜。  

**What:**
- File-based cache under `kits/searxng-search/.cache/` (gitignored) **or** optional Redis (compose profile)
- Key: hash(query + language + category)
- TTL default 24h; `search.ps1 -NoCache` / `-Refresh`
- MVP preference: **filesystem cache first** (no new Docker dependency)

**Acceptance:**
- [ ] Second identical query within TTL does not hit SearXNG (log `cache=hit`)
- [ ] Cache dir gitignored; `tools/up.ps1` docs mention it
- [ ] Redis remains optional Phase 2.1 behind compose profile

**Effort:** S  

### P2-C — CN recall + rate-limit playbook

**Why:** 中文结果偶发偏题；ddg/brave 易 CAPTCHA。  

**What:**
- Settings: document optional engines (`baidu` etc.) as **opt-in**, not default
- `search.ps1`: surface `unresponsive_engines` in Markdown footer
- Kit README: “限流时怎么办” — 降频、换 language、临时加引擎、等 suspended_time
- Optional: simple client-side min-interval (e.g. 1s) between agent calls

**Acceptance:**
- [ ] Empty/partial results show which engines failed
- [ ] README has a short CN + rate-limit section
- [ ] Default engine set unchanged unless user edits settings

**Effort:** S  

## Suggested tracker shape (draft only — Lane A does not create issues)

**Umbrella (draft title):** `feat(searxng-search): Phase 2 research quality (fetch, cache, CN ops)`  

**Children:** P2-A, P2-B, P2-C as above (one issue each).  
Implement order recommendation: **P2-C → P2-B → P2-A** (ops + cache before heavier fetch deps).

## Risks

| Risk | Mitigation |
| --- | --- |
| Fetch increases ToS / robots pressure | Default off; only on explicit “fetch body”; cap N |
| Cache stale news | Short TTL + `-Refresh` |
| Baidu engine flaky in SearXNG | Opt-in only; never block MVP path |

## Success metric

Agent can answer a 高金-style research question with **cited URLs + short excerpts** without Brave API spend, and repeat queries within a session do not hammer upstream.
