---
name: architecture-decision-records
description: Write or update Architecture Decision Records (ADRs) under docs/adr/ using the repo template — context, options, decision, consequences. Use when a choice is hard to reverse, spans modules, or will be questioned later. Trigger phrases — "ADR", "architecture decision", "写 ADR", "记录决策", "docs/adr".
disable-model-invocation: true
---

# Architecture Decision Records

Capture **why** we chose X over Y. ADRs are short structural files — not full design docs.

Template: `docs/templates/adr.md`  
Output dir: `docs/adr/NNN-short-title.md` (zero-pad NNN; never use `docs/decisions/`).

## When to use / when not

Use when the decision:

- Is hard to reverse later
- Affects multiple parts of the system
- Involves real tradeoffs among valid options
- Will be questioned in ~6 months

Don't use when:

- The choice is trivial or fully dictated by an existing ADR
- You need a full design — use `clarify-and-plan` / Lane A design doc; ADR only locks the decision slice
- Pure product/roadmap calls with no technical consequence

## Workflow

1. **Identify** the decision (one decision per ADR).
2. **Research** ≥2–3 options with honest pros/cons.
3. **Draft** from `docs/templates/adr.md` into `docs/adr/NNN-….md`.
   - Next number = max existing NNN + 1 (or `001` if none).
4. **Status**: start as `Proposed`; set `Accepted` when the user approves.
5. **Link** from the design doc / plan (`See ADR-NNN`). Code may cite `// See ADR-NNN`.
6. **Supersede** by setting old status to `Superseded by ADR-MMM` — do not delete.

## Handoffs

- **From `clarify-and-plan` step 8:** when a hard-to-reverse choice appears, draft or remind to draft an ADR here.
- **Lane A (`work-lanes`):** ADR files under `docs/adr/` are valid Lane A artifacts.
- **Not a merge gate:** merging code does not require a new ADR unless the change *is* the decision.

## Guardrails

- Keep to ~1–2 pages; decision ≠ full design.
- Prefer present tense for Accepted ADRs ("We choose X").
- No secrets in ADRs.
