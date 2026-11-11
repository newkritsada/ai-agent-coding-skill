# Memory

Working rules learned on real projects, written so any AI coding assistant can load them
without being taught again. Project-neutral: no repo names, ticket keys or stack names.
Project-only facts stay in that project's own memory or `AGENTS.md`. Rules a skill already covers live in the skill, not here.

| File | Covers |
|---|---|
| [mr-stacking.md](mr-stacking.md) | One chain per feature, 4 MRs + local test branch per feature, frontend split (no-API UI → integrate), CI, review-time rules, shared libraries |
| [agent-orchestration.md](agent-orchestration.md) | Main session vs sub-agent, how many at once, which model, briefs, checks, workspace |
| [frontend-components.md](frontend-components.md) | Component size and split, the main component as an outline of section components, no inner components or layout render props, page owns layout and footer, shared state in a provider, one grid for aligned fields |

## How to load

- **Claude Code**: add one line to a project's `CLAUDE.md` or `~/.claude/CLAUDE.md`:
  `Working rules: read ~/Desktop/Skills/Claude/memory/README.md and the files it lists.`
- **Codex / Cursor / other tools**: point the tool's `AGENTS.md` (or rules file) at the same
  paths, or paste the files' rules into it.

A project's own `AGENTS.md` / `CLAUDE.md` wins where it disagrees: these are defaults.

## Adding a topic

One file per topic. Each rule is short and keeps a one-line *Why* when the reason isn't
obvious. Update the table above in the same change.
