# Design: searxng-search kit

Date: 2026-07-25  
Issue: [#2](https://github.com/Entropy-wz/my-skills/issues/2) (parent [#1](https://github.com/Entropy-wz/my-skills/issues/1))

## Goal

Replace metered Brave Search API usage for routine agent web lookup with a **local SearXNG** instance exposed through a Cursor kit skill. Zero per-query fees; cost shifts to Docker + upstream rate limits.

## Architecture

```
Cursor Agent → skill searxng-search → tools/search.ps1
       → HTTP GET 127.0.0.1:8080/search?format=json
       → SearXNG container → duckduckgo / bing / brave engines
```

## MVP

- `kits/searxng-search/` with docker, tools, skill
- JSON format enabled; bind `127.0.0.1:8080`
- Engines: duckduckgo, bing, brave (Google off)
- Markdown-formatted results for the agent
- Clear error when container is down
- Local `settings.yml` gitignored (secret via `ensure-secret.ps1`)

## Non-goals (Phase 2)

- Full-page fetch / readability
- Redis cache / limiter
- Baidu or other CN-only engines as defaults

## Security

- Loopback bind only
- No secrets committed
- Control query rate from the agent (no tight loops)

## Acceptance (from #2)

See issue checklist; verified by `tools/up.ps1` + EN/ZH `search.ps1` smokes.

## Implementation notes

- Bing is disabled in SearXNG defaults; settings explicitly set `disabled: false`.
- Upstream CAPTCHA/429 on duckduckgo/brave is expected under heavy use; bing + wikipedia soften empty results.


## Implementation notes

- Bing is disabled in SearXNG defaults; settings explicitly set `disabled: false`.
- Upstream CAPTCHA/429 on duckduckgo/brave is expected under heavy use; bing + wikipedia soften empty results.

