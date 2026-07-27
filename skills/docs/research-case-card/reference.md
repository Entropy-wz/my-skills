# research-case-card — reference

## Template field rules (authors / agents — do not paste into Feishu)

| Field | Rule |
| --- | --- |
| source_title | From search hit title or page H1 |
| url | Canonical https URL |
| excerpt | From `fetch.ps1`; truncate; do not invent |
| retrieved_at | Label timezone |
| engine | Optional (`bing`, `duckduckgo`, …) |

## Canonical copies

| Installed (use these) | Repo docs mirror |
| --- | --- |
| `templates/enterprise-case-card.md` | `docs/templates/enterprise-case-card.md` |
| `templates/citation-list.md` | `docs/templates/citation-list.md` (may include extra author notes) |
| `examples/enterprise-case-card-sample.md` | `docs/examples/enterprise-case-card-sample.md` |

After `scripts/install.*`, resolve templates **relative to this skill directory** (sibling `templates/`), not `../../docs/`.

Optional checkout docs: `$env:MY_SKILLS_ROOT/docs/…` if the user wants the longer design notes.
