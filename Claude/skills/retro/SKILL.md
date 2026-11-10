---
name: retro
description: Retrospective on the current Claude session — find what went wrong (user corrections, wrong guesses, retries, denied calls, steps the user had to repeat) and what worked, then propose the smallest fix for each in the right place (a skill, CLAUDE.md / AGENTS.md, memory, settings) and apply the ones the user approves. Use when the user says "retro", "/retro", "retrospective", "look back on this session", "what went wrong", "learn from this", or "update the skills from this session".
---

# Retro

## Uses

None — root skill.

> **Session evidence only. One finding → one smallest fix in the one right place. Nothing changes until the user picks.**

Optional argument: a focus (`/retro the commit step`) — review only that part; or a past session — find its log in `~/.claude/projects/<project>/*.jsonl` by a phrase from it, not by newest file.

## 1. Scan the session

Read back through the whole conversation (or its summary, if compacted — say so). Collect:

| Signal | Look for |
|---|---|
| Correction | the user said no, redid, or overrode what Claude did |
| Repeat | the user had to say the same thing twice |
| Wrong guess | a confident answer later retracted; an assumption the code or user disproved |
| Waste | retries, loops, dead-end searches, questions the code could have answered, costly tool calls (huge reads, slow commands) |
| No-op rule | an instruction in `CLAUDE.md` or a skill that changed nothing Claude did — candidate to delete |
| Denied call | a tool call or permission the user declined |
| Skill miss | a skill that should have loaded and didn't, or loaded and misled |
| Worked | an approach the user confirmed or accepted without change — keep it |

Skip one-offs that won't recur.

## 2. Place each fix

| Cause | Fix goes in |
|---|---|
| A mechanical mistake (banned import, wrong file place, fixed pattern) | an automated check — lint rule, pre-commit hook or CI job; check the repo's existing ones first. Not a written rule |
| A skill's rule was missing, vague, or wrong | that skill's `SKILL.md` — edit the source (`readlink ~/.claude/skills/<name>`), follow the repo's `AGENTS.md` |
| A skill didn't trigger | that skill's `description` trigger phrases |
| Fact about one repo | that repo's `CLAUDE.md` / `AGENTS.md` |
| Preference across all projects | `~/.claude/CLAUDE.md` |
| Fact about the user or ongoing work, not in any file | memory |
| Permission prompts | settings — `/fewer-permission-prompts` or `/update-config` |
| Claude Code product bug | a `SendFeedback` draft |

Fix rules:
- Smallest change: sharpen or delete a rule before adding one.
- Put the fix where the rule already lives; never copy a rule into a second file.
- `CLAUDE.md` / `AGENTS.md` load into every session — add only short rules or pointers to other files there; detail goes in a skill or doc.
- Quote the user's words as evidence; never paraphrase them stronger.

## 3. Report and ask

```
## Retro — <session topic>

| # | What happened | Evidence | Fix → where |
|---|---|---|---|
| 1 | <one line> | "<user quote>" / <tool call> | `<file>` — <exact change> |

Worked (keep): <one line each>

Apply which? all / 1,3 / none
```

## 4. Apply

Make only the picked fixes. If a skill's **Uses** or a new skill changed, sync the repo's skills list and run its linker. Don't commit unless asked. End with the files changed, one line each.
