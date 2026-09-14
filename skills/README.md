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
| `learning/` | university course notes, conversational tutoring, exam review |

`_template/` is never installed. Leaf names must be unique across all categories (and vs kit install names). See **ADR-001**.

Do **not** introduce `modules/` or `plugins/` — only `skills` / `kits` / `tools`.

## University learning

- [`learn-notes`](learning/learn-notes/SKILL.md): chapter-by-chapter Markdown explanations with a course overview and index.
- [`learn-chat`](learning/learn-chat/SKILL.md): explain one course file in conversation and save the content taught so far.
- [`learn-exam`](learning/learn-exam/SKILL.md): knowledge trees, terminology and concept relationships, worked problems, practice sets and mock exams.

These skills can stay in the repository without user-level installation. Point the assistant to the relevant `SKILL.md` to use it directly.
