# Skills

Process / orchestration skills. **In-repo** they live under purpose categories; **install** still flattens to `~/.cursor/skills/<leaf>/`.

```
skills/<category>/<leaf>/SKILL.md  →  ~/.cursor/skills/<leaf>/
```

| Category | Purpose |
| --- | --- |
| `orchestration/` | lanes, menus, ship-gate, multi-task, worktrees |
| `design/` | clarify-and-plan, ADR, architecture improve |
| `quality/` | debugging, incident, skill-fit |
| `review/` | merge/code review, hunk, commit message |
| `docs/` | document delivery, doc-verify, case cards |
| `frontend/` | frontend-craft entry, browser-verify |
| `ci/` | parallel CI triage |

`_template/` is never installed. Leaf names must be unique across all categories (and vs kit install names). See **ADR-001**.

Do **not** introduce `modules/` or `plugins/` — only `skills` / `kits` / `tools`.
