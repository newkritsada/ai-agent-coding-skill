# Plan — template

Copy frontmatter + sections below. Replace `{placeholders}`. Delete sections and subsections that do not apply.

---

```yaml
---
name: {Plan title}
overview: {One sentence — trigger, scope, outcome}
todos:
  - id: {step-one-id}
    content: {First major step}
    status: pending
  - id: {step-two-id}
    content: {Second major step}
    status: pending
  - id: {step-n-id}
    content: {Final major step}
    status: pending
isProject: false
---
```

---

# {Plan title}

## What is needed

### {Prerequisite type — e.g. dependencies, data, config}

- `{name}` — {why or constraint}

### {Another prerequisite type}

{Concrete detail: paths, types, env vars, permissions — as applicable.}

---

## Files to create

```
{root}/
├── {new/file/or/dir}
└── {another/new/path}
```

**Also extend / modify:**

- `{existing/path}` — {what changes}
- `{existing/path}` — {what changes}

---

## How the flow works

### Before (current flow)

{Skip this subsection for greenfield work — nothing exists yet.}

```mermaid
flowchart TD
  subgraph entry [{trigger or entry point}]
    A[Start] --> B[Current step]:::changed
    B --> stop[Exit]
  end
  classDef changed stroke-dasharray: 5 5
```

### After (planned flow)

```mermaid
flowchart TD
  subgraph entry [{trigger or entry point}]
    A[Start] --> B{condition?}:::changed
    B -->|no| stop[Exit]
    B -->|yes| C[Next step]:::changed
  end

  subgraph core [{main module or orchestrator}]
    C --> D[Step 1]:::changed
    D --> E[Step 2]:::changed
  end

  subgraph side [{external effect or persistence}]
    E --> F[Persist / notify / emit]:::changed
  end
  classDef changed stroke-dasharray: 5 5
```

Keep node IDs and layout identical between Before and After where the flow is unchanged; tag added/modified nodes with `:::changed`.

### {Rule name — e.g. completion, retry, naming}

{Plain language or short snippet showing the rule.}

### Completion criteria

{When is a unit, job, or record considered done?}

---

## {Optional — constants / shared definitions}

{Only when the plan needs a named list of values, keys, or types.}

---

## Implementation order

1. {Foundation — deps, schema, types, etc.}
2. {Core building blocks}
3. {Main logic / orchestrator}
4. {Wiring — entry points, config, integration}
5. {Verification or rollout step if needed}

---

Each numbered item above should have a matching `todos` entry in frontmatter.
