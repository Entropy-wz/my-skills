---
name: doc-verify
description: Verify Markdown structure and fix or report broken links in documentation deliverables. Default closing gate for document-delivery. Trigger phrases — "doc-verify", "校验文档", "检查死链", "verifying-markdown", "fixing-broken-links".
disable-model-invocation: true
---

# Doc Verify

Two checks, one entry: **markdown hygiene** + **broken links**.

## When to use / when not

Use after drafting docs (especially via `document-delivery`) or when the user asks to
audit markdown/links.

Don't use as a substitute for writing the doc, or for code review.

## A — Markdown structure

For each target file:

- [ ] Single clear H1 (or repo-conventional title)
- [ ] Heading levels don't skip (H2 → H4)
- [ ] Fenced code blocks closed; language tags where useful
- [ ] Lists/tables render sanely; no obvious broken pipes
- [ ] No leftover placeholders (`TODO`, `TBD`, `lorem`, `??`) unless marked intentional
- [ ] Mode templates: required sections present (T/P/D)

Fix safe issues; list judgment calls for the user.

## B — Broken links

1. Collect links: markdown `[text](url)`, autolinks, and obvious bare URLs in the file.
2. Classify: `http(s)` remote · relative repo path · anchors `#…`.
3. **Remote:** HEAD/GET with short timeout; record status. Treat 404/410 as fail; 401/403
   as "auth-walled" (warn, not always fail). Offline → say so, don't fake pass.
4. **Relative:** resolve from file dir; fail if missing.
5. **Anchors:** best-effort against heading slugs; warn if unsure.
6. Report table: link · result · action (fixed / needs human).

Prefer fixing typos/moved paths when obvious; don't rewrite content to dodge bad sources.

## Handoffs

- Called by `document-delivery` as the default closing gate.
- Evidence-heavy docs may also need citation review from `research-case-card` habits.

## Guardrails

- Never claim "all links OK" without running checks (or explicit skip with reason).
- No secrets in fetched URLs logged to git.
- No remote git push from this skill.
