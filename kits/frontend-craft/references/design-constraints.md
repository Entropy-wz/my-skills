# Frontend design constraints (toolkit)

Adapted for agents — **not** a copy of Anthropic `frontend-design` SKILL.

## Direction

- Pick one clear visual direction; define CSS variables early.
- Prefer expressive, purposeful fonts — avoid default stacks (Inter, Roboto, Arial, system) unless the product already uses them.
- Backgrounds: avoid flat single-color only; use subtle gradient/texture/image for atmosphere when it fits the brand.
- Imagery should show real product/place/context when the UI is marketing-led.

## Anti-patterns (avoid unless the existing design system requires them)

- Purple-on-white / purple-to-indigo “AI default” themes
- Warm cream + terracotta + generic serif “brochure” look as a default
- Broadsheet dense newspaper layouts as a default
- Hero packed with stats, schedules, chips, floating badges
- Cards everywhere (especially in heroes) when plain layout works
- Glow stacks, rounded-full pill clusters, emoji decoration as substance

## Composition

- First viewport = one composition (unless the product is a dashboard).
- Brand-first on branded surfaces; one headline + one supporting line + one CTA group.
- One job per section.

## Performance / React (when stack is React/Next)

Prefer Vercel-style guidance in spirit: avoid request waterfalls, keep bundles honest,
respect server/client boundaries — pull project rules if present
(`react-best-practices` vendor notes may be added under this kit later).
