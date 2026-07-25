# Citation list template（引用清单）

**Installed / agent-facing paste block** lives in the skill (keeps Feishu paste clean):

`skills/research-case-card/templates/citation-list.md`

Mirror the paste section there. Field rules below are for authors only — **do not** ask agents to paste this table into Feishu.

---

## 引用清单

Retrieved: \<ISO date, timezone labeled, e.g. 2026-07-25 (UTC+8)\>  
Tooling: local SearXNG (`searxng-search`) + `fetch.ps1` — research / citation use only.

1. **\<source_title\>**
   - URL: \<https://…\>
   - Excerpt: \<≤ ~400 chars; prefer short quote; no secrets\>
   - Engine: \<optional, from search\>
   - Retrieved: \<same as header or per-row if staggered\>

2. **\<source_title\>**
   - URL: …
   - Excerpt: …
   - Engine: …
   - Retrieved: …

---

### Field rules (authors only — not for Feishu paste)

| Field | Rule |
| --- | --- |
| source_title | From search hit title or page H1 |
| url | Canonical https URL |
| excerpt | From `fetch.ps1`; truncate; do not invent |
| retrieved_at | Label timezone |
| engine | Optional (`bing`, `duckduckgo`, …) |
