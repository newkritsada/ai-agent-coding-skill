---
name: clean-architecture
description: Code style when writing code — picks and applies the right architecture skills for the change. Structure (new handler, use case, repository, port, entity, migration, controller, module, or a change across layers) → port-adapter-architecture for placement plus clean-function for every function it creates; code inside one layer → clean-function only. Use when building code from a plan, or writing a backend feature, module, service or use case.
---

# Clean architecture

## Uses

Load a skill by name: read `~/.claude/skills/<name>/SKILL.md`.

1. `/port-adapter-architecture` — layers, ports, where code belongs
2. `/clean-function` — the body of every function written

## Pick

Decide from what the change creates or touches — a plan's §3–§4, else the request:

| Change | Read and follow |
|---|---|
| **Structure** — creates a handler, use case, repository, port, entity, migration, controller or module, or touches two or more layers | `/port-adapter-architecture` **and** `/clean-function` |
| **Function** — inside one layer: logic, specs, helpers | `/clean-function` |

Frontend code (components, hooks, stores, pages) → neither skill; follow the repo's style.

Planning (no code yet) → only the placement skill matters: port-adapter-architecture for structure, nothing for function-only.

Delegating to agents → pass the picked skill paths, not this file.

## Apply

1. Structure first: layers, files, ports, adapters — per port-adapter-architecture.
2. Every function those files hold — per clean-function: the orchestrator reads as named steps, each step small.
3. They disagree → port-adapter-architecture decides **where** code lives, clean-function decides **how** a body reads.
