# Kit: searxng-search

Self-hosted [SearXNG](https://docs.searxng.org/) + Cursor skill for **zero paid search API** web lookup.

Tracks: https://github.com/Entropy-wz/my-skills/issues/2

## Prerequisites

- Docker Desktop (Windows, WSL2 backend OK)
- This repo checked out locally

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
| `docker/searxng/settings.example.yml` | Committed template (JSON on; engines: ddg/bing/brave) |
| `docker/searxng/settings.yml` | Local only (gitignored; created by `ensure-secret.ps1`) |
| `tools/search.ps1` | Agent-facing search CLI |
| `tools/up.ps1` | Secret + `docker compose up -d` |
| `skill/SKILL.md` | Cursor skill |

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
- Phase 2 (not in MVP): page fetch, Redis cache, extra CN engines.
