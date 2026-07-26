---
name: document-delivery
description: Produce finished documents in mode T (technical deep), P (presentation brief), or D (design brief) — outline approval, write from templates, optional export notes for PDF/Word/PPT/Excel. Not a vendor copy of Anthropic doc skills. Trigger phrases — "document-delivery", "文档交付", "Mode T", "Mode P", "Mode D", "写汇报", "技术文档成稿".
disable-model-invocation: true
---

# Document Delivery

Ship **finished** docs in one of three modes. Transformed for this toolkit — do **not**
paste upstream Anthropic Office skill bodies.

| Mode | Template | Voice |
| --- | --- | --- |
| **T** Technical | `docs/templates/doc-technical.md` | Complete, citable, verifiable |
| **P** Present | `docs/templates/doc-report-present.md` | Short showcase narrative |
| **D** Design | `docs/templates/doc-report-design.md` | Short structural / underlying |

## When to use / when not

Use when the user wants a deliverable document (report, design brief, tech write-up).

Don't use when:

- Only collecting research evidence → `research-case-card` first, then return here
- Only an ADR → `architecture-decision-records`
- Only link/markdown hygiene → `doc-verify`

## Flow

1. **Pick mode** T / P / D (ask if unclear). Never mix voices in one file — split instead.
2. **Outline** — section list from the template; get approval before long prose.
3. **Draft** into the target path (user-specified, or `docs/report/` / `docs/design/` as appropriate).
4. **Evidence** — for T (and P/D when claims are factual): prefer case cards / citations with
   URL + retrieved date; no fabricated sources. Align with `research-case-card` citation habits.
5. **Export (optional)** — if user wants PDF/Word/PPT/Excel:
   - Prefer existing local tooling the repo already uses (Pandoc, reportlab, office CLIs).
   - State exact command + input/output paths; do not invent paid APIs.
   - Keep Markdown source as source of truth.
6. **Close with `doc-verify`** — markdown structure + broken-link check before calling done.

## Guardrails

- No verbatim vendor SKILL dumps.
- Mode P: ruthlessly cut implementation detail.
- Mode D: no marketing fluff; point to full design/ADR.
- Mode T: include Verification section.
- No push/PR unless user switches to `work-lanes` Lane C.
