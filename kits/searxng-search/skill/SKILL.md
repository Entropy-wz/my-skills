---
name: searxng-search
description: Search the web via a local self-hosted SearXNG instance (zero paid API cost). Use for current facts, external sources, case studies, research links, and Chinese/English web lookup. Prefer this over Brave web-search to avoid metered API fees. Trigger phrases — "searxng", "本地搜索", "免费网页搜索", "search the web", "查一下网上", "搜一下资料".
---

# SearXNG Search

Local meta-search through Dockerized SearXNG. No Brave/Tavily/SerpAPI keys.

## Prerequisites

1. Docker Desktop running
2. Start the instance once:

```powershell
cd kits/searxng-search
powershell -File tools/up.ps1
```

Health check (must return JSON, not 403 HTML):

```powershell
curl "http://127.0.0.1:8080/search?q=test&format=json"
```

## When to use

- Need **live / external** web information
- Research, fact-check, case studies, news-ish lookup
- Prefer **this skill over paid Brave `web-search`** when both are installed

Do **not** use for pure local-code questions that need no web data.

## How to search

From the toolkit repo root (or absolute path to this kit):

```powershell
powershell -File kits/searxng-search/tools/search.ps1 -Query "<query>" -Language auto -Count 8
```

Chinese-heavy queries:

```powershell
powershell -File kits/searxng-search/tools/search.ps1 -Query "数字金融 案例 研究报告" -Language zh-CN -Count 8
```

English:

```powershell
powershell -File kits/searxng-search/tools/search.ps1 -Query "digital finance custody case study" -Language en -Count 8
```

## Output

Markdown blocks with title, URL, snippet, and engine. Cite URLs when answering the user.

## Failures

| Symptom | Action |
| --- | --- |
| Connection refused | Run `tools/up.ps1`; confirm Docker is up |
| HTTP 403 | `search.formats` missing `json` — fix example/settings and restart |
| Empty results | Retry once; try `zh-CN` / `en`; upstream may be rate-limiting |

## Defaults (MVP)

- Engines: duckduckgo, bing, brave (Google off)
- Bind: `127.0.0.1:8080` only
- No page-body fetch / Redis (Phase 2)

## Priority

If a Brave Search skill is also available, **prefer SearXNG** unless the user explicitly asks for Brave API features (Goggles, Answers, etc.).
