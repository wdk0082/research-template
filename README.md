# research-template

Reusable workflow scaffold for iterative ML-research projects — the
compute-agnostic version of `tpu-research-template`, with the Cloud-TPU
layer removed. What's kept: the agent working rules, the experiment
plan/notebook discipline, and the env/wrapper conventions.

## Layout

```text
instructions/           # externally provided instructions (specs, handoffs, briefs) — NN_<slug>.md
CLAUDE.md               # working rules for coding agents
REPOSTART.md            # repo conventions (uv, env vars, outputs) — scaffold from this
CONCLUSIONS.md          # important conclusions — added only after discussion
.env / .env.example     # runtime config (.env is gitignored)
bin/run                 # env-loading command wrapper — run everything through this
experiments/guides/     # PLAN_AND_NOTEBOOK.md, HP_SWEEP.md, REPORTS.md — workflow guides
.github/workflows/      # CI: ruff lint + format check + pytest
```

Not included — scaffold per `REPOSTART.md` once the project starts:
`pyproject.toml`, `uv.lock`, `src/<pkg>/`, `tests/`, `configs/`,
`experiments/PLANS.md` + `experiments/NOTEBOOKS.md`, and any remote-compute
backend (a `gcp/`, `slurm/`, `ssh/`, … dir — see "Remote Compute" in
`REPOSTART.md`; `tpu-research-template` is a worked Cloud-TPU example).

## Compute model

Local-first and device-agnostic. `DEVICE` in `.env` selects the accelerator
(`cuda` / `mps` / `cpu`; blank = auto-detect), and experiments write durable
outputs under `$ARTIFACT_DIR` and `$CKPT_DIR` (`./artifacts` and
`./checkpoints` by default — both gitignored):

```text
Machine                  ──  runs experiments via ./bin/run (own .env + .venv)
   │
   ▼
$ARTIFACT_DIR/exp_NNN/   ──  plots, tables, logs        (durable, gitignored)
$CKPT_DIR/exp_NNN/       ──  best + final checkpoints   (durable, gitignored)
```

If a project outgrows local compute, add a backend dir per the "Remote
Compute" conventions in `REPOSTART.md` — remote machines are disposable,
durable state lives in a durable store, training is resumable.

## Starting a new project

1. Copy this directory, rename it after the project, and re-init git history
   if you want a clean start.
2. Drop the initial instruction document — spec, brief, or handoff, whatever
   starts the project — into `instructions/00_<slug>.md`; each later arrival
   takes the next number (see `instructions/README.md`).
3. Scaffold the Python side per `REPOSTART.md`: `pyproject.toml` (src-layout
   package, hatchling; ruff + pytest config), `uv sync --all-groups`, then
   `src/<pkg>/` and `tests/` as the instructions demand.
4. `cp .env.example .env` and fill it in (`DEVICE`, output dirs,
   `WANDB_PROJECT`, secrets).
5. Run the loop: `./bin/run python experiments/NNN_*.py`, inspect
   `$ARTIFACT_DIR/exp_NNN/`, iterate per `experiments/guides/`.

Note: `.github/workflows/ci.yml` expects `pyproject.toml`/`uv.lock`, so CI
fails until step 3 is done. The agent working rules and per-experiment
workflow live in `CLAUDE.md` and `experiments/guides/`.
