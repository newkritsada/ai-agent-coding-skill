---
name: plan-clean-structure
description: Build a .plan.md (plan-pattern) with the right code-style skill loaded — clean-architect for structure, function-flow for function bodies. Manual launcher — invoke with /plan-clean-structure.
disable-model-invocation: true
---

Read the plan file (given path, else the last `Plan saved at:`, else the newest `*.plan.md` under `.claude/plans/`). Plan file ends in plain `.md` → `mv` it to `{name}.plan.md` and fix its `Plan saved at:` line first. Decide scope from §3–§4 only, then read and follow exactly one skill:

- **Structure** — §3 creates a handler, use case, repository, port, entity, migration, controller or module, or §4 touches two or more layers → `../clean-architect/SKILL.md`.
- **Function** — everything else (§3 empty or specs/helpers only, §4 inside one layer) → `../function-flow/SKILL.md`.

Then execute §7 in order, updating each frontmatter todo `status` as you go. End with `Plan saved at: /abs/path/to/file.plan.md`.
