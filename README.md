# tpu-research-template

Reusable workflow scaffold for iterative ML-research projects on Cloud TPU,
extracted from `sccg-extraction` with the project content removed. What's
kept: the agent working rules, the experiment plan/notebook discipline, and
the TPU lifecycle scripts.

## Layout

```text
instructions/           # externally provided instructions (spec, handoffs) — NN_<slug>.md
CLAUDE.md               # working rules for coding agents
REPOSTART.md            # repo conventions (uv, env vars, GCP/TPU layout) — scaffold from this
CONCLUSIONS.md          # important conclusions — added only after discussion
.env / .env.example     # runtime config (.env is gitignored)
bin/run                 # env-loading command wrapper — run everything through this
experiments/guides/     # PLAN_AND_NOTEBOOK.md, HP_SWEEP.md — workflow guides
gcp/                    # Cloud TPU lifecycle scripts (create / launch / pull / teardown)
.github/workflows/      # CI: ruff lint + format check + pytest
```

Not included — scaffold per `REPOSTART.md` once the project starts:
`pyproject.toml`, `uv.lock`, `src/<pkg>/`, `tests/`, `configs/`, and
`experiments/PLANS.md` + `experiments/NOTEBOOKS.md`.

## Compute model (Cloud TPU)

Training runs on a **Google Cloud TPU** (`v6e`), treated as **disposable
compute** — created per run and deleted when idle, so nothing runs 24/7.
Durable state lives in **Google Cloud Storage**, not on the TPU:

```text
GCS bucket  ──  datasets, checkpoints, logs, artifacts  (durable; YOUR project)
   │            gs://dis-2026-zw499-tpu-store  (us-east5)
   ▼
TPU VM      ──  ephemeral compute: create → train → DELETE
   │            (course project dis-2026-tpu-zw499 — compute only)
   ▼
Local       ──  orchestrate (gcp/ scripts) + pull artifacts + commit to repo
```

Everything goes through `gcp/` — see `gcp/README.md`. Checkpoints write
straight to the bucket, so a deleted or preempted TPU costs only a resume.

## Starting a new project

1. Copy this directory, rename it after the project, and re-init git history
   if you want a clean start.
2. Drop the project spec into `instructions/00_<slug>.md` — later handoffs
   take the next number (see `instructions/README.md`).
3. Scaffold the Python side per `REPOSTART.md`: `pyproject.toml` (src-layout
   package, hatchling; ruff + pytest config), `uv sync --all-groups`, then
   `src/<pkg>/` and `tests/` as the spec demands.
4. Update `.env`: set `GIT_REMOTE` (and generate a fresh per-repo
   `gcp/keys/deploy_key` if the repo is private) once pushed; set
   `WANDB_PROJECT` per project.
5. One-time `gcp/setup_storage.sh`, then the loop:
   `gcp/create.sh` → `gcp/launch.sh experiments/NNN_*.py` → `gcp/pull.sh` →
   `gcp/teardown.sh`.

Note: `.github/workflows/ci.yml` expects `pyproject.toml`/`uv.lock`, so CI
fails until step 3 is done. The agent working rules and per-experiment
workflow live in `CLAUDE.md` and `experiments/guides/`.
