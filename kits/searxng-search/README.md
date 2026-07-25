# Kit: searxng-search

Self-hosted [SearXNG](https://docs.searxng.org/) + Cursor skill for **zero paid search API** web lookup.

Tracks: https://github.com/Entropy-wz/my-skills/issues/2  
Phase 2 design: [`docs/design/2026-07-25-searxng-phase2.md`](../../docs/design/2026-07-25-searxng-phase2.md)

## Prerequisites

- Docker Desktop (Windows, WSL2 backend OK)
- This repo checked out locally
- Optional for better page extraction: `pip install trafilatura`

## Quick start

```powershell
cd kits/searxng-search
powershell -File tools/up.ps1
powershell -File tools/search.ps1 -Query "searxng json api" -Count 5
```

Install the skill into Cursor:

```powershell
# from repo root
./scripts/install.ps1 -Copy
```

## Layout

| Path | Role |
| --- | --- |
| `docker/` | `docker-compose.yml` + SearXNG config |
| `docker/searxng/settings.example.yml` | Committed template (JSON on; engines: ddg/bing/brave/wiki) |
| `docker/searxng/settings.yml` | Local only (gitignored; created by `ensure-secret.ps1`) |
| `.cache/` | Filesystem query cache + live-request throttle (gitignored) |
| `tools/search.ps1` | Agent-facing search CLI (cache, unresponsive engines) |
| `tools/fetch.ps1` | Fetch main text for top URLs (research / cite) |
| `tools/up.ps1` | Secret + `docker compose up -d` |
| `skill/SKILL.md` | Cursor skill |

## Search options

```powershell
./tools/search.ps1 -Query "…" -Language zh-CN -Count 8
./tools/search.ps1 -Query "…" -Refresh      # bypass cache, rewrite entry
./tools/search.ps1 -Query "…" -NoCache      # never read/write cache
```

Default cache TTL is 24h under `.cache/`. Live SearXNG calls are spaced by `-MinIntervalSec` (default 1).

## Fetch body (research)

```powershell
./tools/fetch.ps1 -Url "https://example.com/a","https://example.com/b" -MaxChars 4000
# powershell -File may collapse "a","b" into one arg; script splits comma-joined http(s) URLs:
powershell -File ./tools/fetch.ps1 -Url "https://example.com/a,https://example.com/b"
```

**Policy:** research / citation only. Quote short excerpts and always cite the source URL. Do not run tight fetch loops. Prefer `trafilatura` (`pip install trafilatura`); otherwise HTML-strip fallback is used. One URL failure does not abort the batch.

**Robots:** `fetch.ps1` does **not** fetch or honor `robots.txt`. Intended for explicit user research / citation only — do not use for bulk scraping or to bypass site terms.

## CN recall + rate-limit playbook

Defaults stay **duckduckgo / bing / brave / wikipedia / wikidata**. Do **not** add Baidu (etc.) unless you opt in.

When results are empty or thin:

1. Read the Markdown footer **Unresponsive engines** (CAPTCHA / timeout / suspended).
2. Wait for SearXNG `suspended_time`, or lower agent query rate.
3. Retry with `-Language zh-CN` or `en`.
4. Optional: edit local `docker/searxng/settings.yml` to opt-in an engine (see comments in `settings.example.yml`), then `docker compose restart`.
5. Prefer cache hits for repeat queries (`cache=hit` on stderr); use `-Refresh` only when you need fresh news.
6. Empty / zero-hit responses are **not** written to cache (so waiting out CAPTCHA then retrying works without `-Refresh`).

## Ops

```powershell
cd docker
docker compose ps
docker compose logs -f searxng
docker compose restart
docker compose stop
```

## Notes

- Listens on **127.0.0.1:8080** only — do not publish to LAN/public without auth.
- Google is **not** in the default engine set (CAPTCHA risk).
- Redis cache is deferred (filesystem cache is Phase 2).
