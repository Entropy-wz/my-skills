---
name: incident-response
description: Handle production incidents — severity, mitigate, communicate, resolve, blameless postmortem. Hotfix may skip full clarify-and-plan but does not waive work-lanes Lane C gates. Trigger phrases — "incident-response", "线上事故", "SEV", "postmortem", "故障响应".
disable-model-invocation: true
---

# Incident Response

Systematic production incident handling for team collaboration.

Postmortem template: `docs/templates/postmortem.md`

## When to use / when not

Use for production (or staging-with-user-impact) incidents.

Don't use for routine bugs with no incident process — use `systematic-debugging`.

## Severity (adapt names to your org)

| Level | Meaning | Response |
| --- | --- | --- |
| SEV1 | Service down / all users | Immediate |
| SEV2 | Major feature broken / many users | Urgent |
| SEV3 | Limited impact | Planned business hours OK |
| SEV4 | Minor / cosmetic | Backlog |

## Flow

### 1. Triage

Declare SEV, impact, and Incident Commander (even if it's you).

### 2. Mitigate (speed > elegance)

Prefer: rollback · feature flag off · scale out · failover · block abusive traffic.  
**Mitigation before deep root-cause.**

### 3. Communicate

- Internal channel + updates every 15–30 min while SEV1/2  
- External status if users are affected  
- Honest, no blame in live updates  

### 4. Resolve

Deploy/confirm fix; verify with **metrics/symptoms**, not "errors stopped in my terminal".  
Close the incident with a short summary.

### 5. Root cause

Hand to `systematic-debugging` once users are safe.

### 6. Postmortem (≤48h)

Fill `docs/templates/postmortem.md` — blameless; action items with owners/dates.  
Optional ADR if the fix changes architecture/process.

## work-lanes handoff

- Hotfix may **skip full `clarify-and-plan`** — say so explicitly.
- Hotfix does **not** waive lane gates: push/PR still need Lane C commit hygiene and
  gate evidence (or an **explicit** user override recorded in-session).
- Prefer `/ship-gate` before claiming shipped.

## Guardrails

- Rollback first when a recent deploy is the likely cause.
- No blame in postmortems — fix process.
- No secrets in timelines or status posts.
