# `instructions/` — externally provided instructions

Documents handed to the project from outside (user / supervisor): the project
spec ("prototype"), research-line handoffs, mid-project redirections. They are
**read-only inputs** — reference them in place from `CLAUDE.md`, plans, and
notebooks; never edit, fork, or restate them wholesale in other docs.

## Naming

`NN_<snake_case_slug>.md`, numbered in arrival order:

```text
instructions/
  00_prototype.md         # the project spec — first thing dropped in
  01_<line>_handoff.md    # e.g. a later handoff opening a new research line
```

- A new document takes the next free number; numbers are never reused or
  reshuffled.
- Read all files in numeric order. Where two conflict, the newer file wins.
