# Skills

Every skill in `Claude/`, what it does, and what it uses. Each `SKILL.md` starts with the same **Uses** list.
A skill loads another by name — `~/.claude/skills/<name>/SKILL.md` — so moving a source folder only needs the linker re-run.

## List

| Skill | Started by | Kind | Does |
|---|---|---|---|
| `/plan-feature` | you | composed | BE diagram → FE diagram → summary plan with branch stack + build order |
| `/build-stack` | you | composed | build the summary's stack, parallel where Needs allow; review; push + MR |
| `/build-plan` | you | composed | build any plan's §7 in the picked code style |
| `/plan-diagram-archify` | you / plan-feature | composed | plan + archify diagrams in one Artifact |
| `/grill-me` | you | composed | grilling session on a plan or design |
| `/plan-pattern` | Claude (any plan) | composed | plan file shape, grilling, `Plan saved at` |
| `/clean-architecture` | Claude / build skills | composed | pick + apply code style: structure → both roots, one layer → clean-function |
| `/commit-checkpoint` | Claude | root | checkpoint commit order, branch stack, Needs, build order |
| `/port-adapter-architecture` | Claude | root | layers, ports & adapters, where code belongs |
| `/clean-function` | Claude | root | function bodies as named steps |
| `/grilling` | Claude | root | the interview |
| `/to-prd` | you | root | conversation → PRD published to the issue tracker |
| `/timesheet` | you | root | Taskfolio timesheet review / update / push |
| `/graphify` | you | root (upstream copy) | folder → knowledge graph |
| `/pr-description` | you | local only, git-ignored | MR description from the diff — currently missing |

Root = uses no other skill. Composed = binds others; see its **Uses**.

## Structure

```
/plan-feature                         plan a feature in 3 gated stages
├── /plan-diagram-archify             write the BE and FE plans + render their diagrams
│   ├── /plan-pattern                 plan file shape: 8 sections, todos, Plan saved at
│   │   └── /grilling                 interview you before filling the plan
│   ├── archify                       draw the diagrams (external: npx skills add tt-a1i/archify -g)
│   └── /build-plan                   only if you ask to build code from a diagram plan
├── /plan-pattern                     write the summary plan
│   └── /grilling                     interview on branch boundaries and Needs
├── /clean-architecture  (Pick)       decide where planned files go (§3–§4), no code
│   ├── /port-adapter-architecture    layers, ports, module structure
│   └── /clean-function               not used while planning
└── /commit-checkpoint                §7: branch stack, checkpoint commits, Needs, build order

/build-stack                          build the stack, review, push
├── /commit-checkpoint                commit order, green-alone rule, Needs → parallel waves
├── /clean-architecture  (Pick)       choose which code-style skills each agent loads
│   ├── /port-adapter-architecture    structure branches: where code goes
│   └── /clean-function               every branch: how each function body reads
└── /pr-description                   MR description on "push" (if present)

/build-plan                           build one plan's §7, no stack
├── /plan-pattern                     find the plan, tick todos as steps finish
│   └── /grilling                     not used while building
└── /clean-architecture               code style for the build
    ├── /port-adapter-architecture    structure: where code goes
    └── /clean-function               every function body

/grill-me                             start a grilling session yourself
└── /grilling                         the interview rules

/to-prd                              conversation → PRD in the issue tracker
└── /setup-matt-pocock-skills        tracker + labels setup, only if missing (external)

roots (use nothing): /commit-checkpoint · /port-adapter-architecture · /clean-function · /grilling · /timesheet · /graphify
```

Flow walkthrough: [plan-build-flow.md](plan-build-flow.md).
