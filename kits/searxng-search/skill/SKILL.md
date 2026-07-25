---
name: searxng-search
description: Search the web via a local self-hosted SearXNG instance (zero paid API cost). Use for current facts, external sources, case studies, research links, and Chinese/English web lookup. Prefer this over Brave web-search to avoid metered API fees. For deep/body/cite requests, search then fetch top URLs. Trigger phrases — "searxng", "本地搜索", "免费网页搜索", "search the web", "查一下网上", "搜一下资料", "抓正文", "引用原文".
---

# SearXNG Search

Local meta-search through Dockerized SearXNG. No Brave/Tavily/SerpAPI keys.

## Prerequisites

1. Docker Desktop running
2. Start the instance once:

```powershell
# From installed skill dir (~/.cursor/skills/searxng-search) or kit checkout:
powershell -File tools/up.ps1
```

Health check (must return JSON, not 403 HTML):

```powershell
curl "http://127.0.0.1:8080/search?q=test&format=json"
```

Optional (better page extract): `pip install trafilatura`

## When to use

- Need **live / external** web information
- Research, fact-check, case studies, news-ish lookup
- Prefer **this skill over paid Brave `web-search`** when both are installed
- User asks for **深度 / 正文 / 引用** → search, then `tools/fetch.ps1` on top 3–5 URLs

Do **not** use for pure local-code questions that need no web data.

## How to search

After `scripts/install.*`, this skill folder contains `SKILL.md` plus sibling `tools/` (and `docker/`). Run from the installed skill directory (or any path that resolves `tools/search.ps1`):

```powershell
powershell -File tools/search.ps1 -Query "<query>" -Language auto -Count 8
```

Chinese-heavy queries:

```powershell
powershell -File tools/search.ps1 -Query "数字金融 案例 研究报告" -Language zh-CN -Count 8
```

English:

```powershell
powershell -File tools/search.ps1 -Query "digital finance custody case study" -Language en -Count 8
```

Repeat queries within 24h usually hit the filesystem cache (`cache=hit`). Use `-Refresh` for fresh news, `-NoCache` to skip cache entirely.

From the toolkit repo (before/without install), use `kits/searxng-search/tools/search.ps1` instead.

## Deep / body / cite

When the user wants excerpts or citations (not just snippets):

1. Run `search.ps1` as usual
2. Pick top 3–5 URLs
3. Run:

```powershell
# Direct invoke (array):
powershell -File tools/fetch.ps1 -Url "https://example.com/a","https://example.com/b" -MaxChars 4000
# Under -File, "a","b" often collapses to one arg — script also splits comma-joined http(s):
powershell -File tools/fetch.ps1 -Url "https://example.com/a,https://example.com/b" -MaxChars 4000
```

Cite source URLs in the answer. Prefer short quotes. Do not hammer fetch in a tight loop.  
Robots: `fetch.ps1` does not honor robots.txt — use only for explicit user research; no bulk scrape.

## Output

- Search: Markdown with title, URL, snippet, engine; footer lists **Unresponsive engines** when upstream fails
- Fetch: per-URL excerpt with `Source:` line

## Failures

| Symptom | Action |
| --- | --- |
| Connection refused | Run `tools/up.ps1`; confirm Docker is up |
| HTTP 403 | `search.formats` missing `json` — fix example/settings and restart |
| Empty results / unresponsive engines | Wait; try `zh-CN` / `en`; see kit README rate-limit playbook |
| Fetch error on one URL | Continue with others; try another link |

## Defaults

- Engines: duckduckgo, bing, brave, wikipedia, wikidata (Google off; Baidu etc. opt-in only)
- Bind: `127.0.0.1:8080` only
- Filesystem cache under kit `.cache/` (TTL 24h); Redis not required

## Priority

If a Brave Search skill is also available, **prefer SearXNG** unless the user explicitly asks for Brave API features (Goggles, Answers, etc.).
