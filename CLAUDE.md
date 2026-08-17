# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Read these for context — don't restate them here:

- `instructions/` — externally provided project instructions (specs /
  prototypes, handoffs, briefs — any kind, in any order). Files are named
  `NN_<slug>.md` in arrival order; read all of them, in numeric order. See
  `instructions/README.md`.

Layout:

- **`src/<pkg>/`** — core library (package name and submodules set by the project instructions)
- **`experiments/`** — `# %%` cell-style Python scripts with config-at-top pattern
- **`tests/`** — pytest tests

**Framework: PyTorch** by default (the project instructions may override).
Write device-agnostic code — select the device from `$DEVICE` (`cuda` /
`mps` / `cpu`; blank = auto-detect). Work proceeds in iterations (as set out
in `instructions/`); per-experiment state lives in `experiments/PLANS.md` +
`experiments/NOTEBOOKS.md` (one `# EXP<NNN>` section each).

## Environment

**Run everything via `./bin/run`:** `./bin/run python ...`, `./bin/run pytest`, `./bin/run ruff check tests experiments`. The wrapper sources `.env` and prepends `$REPO_DIR/.venv/bin/` to PATH, then execs. Never call bare `python` or `uv run` for execution — bare `python` lacks env vars / wrong interpreter.

**Each machine the repo runs on has its own `.env` and `.venv`** (both
gitignored), derived from `.env.example` and `uv.lock`. `DEVICE` and the
output paths are the usual per-machine differences.

**For dependency management** (`uv add`/`uv remove`/`uv sync`/`uv lock`): run on your laptop, then commit `uv.lock`. Any other machine installs from the lockfile (`uv sync --frozen`). It's a src-layout package (hatchling; package name set by the project instructions). Platform-specific accelerator packages are installed per-machine, not tracked in `pyproject.toml`, so the lockfile stays cross-platform.

## Compute & durable outputs

- Experiments run locally by default; `DEVICE` in `.env` picks the
  accelerator. If the project adds remote compute, follow "Remote Compute"
  in `REPOSTART.md`: **remote machines are disposable; durable state never
  lives only on one.**
- **Durable outputs:** artifacts under `$ARTIFACT_DIR/exp_NNN/`, checkpoints
  under `$CKPT_DIR/exp_NNN/` (`./artifacts` and `./checkpoints` by default;
  gitignored).
- **Make long training resumable:** save a checkpoint every ~15–30 min and
  restore the latest on start.

## Code Style

- Ruff for linting and formatting (configured in `pyproject.toml`)
- Line-length 100, target Python 3.11
- Uses `from __future__ import annotations` throughout

## Experiment Outputs

Each experiment saves artifacts under `$ARTIFACT_DIR/exp_NNN/` and
checkpoints under `$CKPT_DIR/exp_NNN/`.

- **Plots:** concise and highly informative — minimal clutter, clear labels, one takeaway per figure. Use Plotly and save as HTML (`fig.write_html()`); **also dump PNGs** so they can be read directly (see `experiments/guides/HP_SWEEP.md`).
- **Logging (printed output):** comprehensive — include all key numbers; use table format where possible.
- **Checkpoints:** always save `best` and `final` (when applicable).
- **Reports:** at each round close, publish/update the experiment's
  interactive report artifact and record its URL in the round's notebook
  entry — see `experiments/guides/REPORTS.md`. The md notebook stays the
  record of record; each run writes `summary.json` + `metrics.jsonl` so
  reports are rebuildable.

## Experiment Workflow

When given a research topic or question:

1. **Plan** — Add an `# EXP<NNN>` section to `experiments/PLANS.md`. See `experiments/guides/PLAN_AND_NOTEBOOK.md`.
2. **Script** — Create `experiments/NNN_*.py` implementing the plan. Config at top, `# %%` cell style.
3. **Notebook** — Add an `# EXP<NNN>` section to `experiments/NOTEBOOKS.md` and run rounds against the plan. See the guide.
4. **Iterate** — Continue running rounds, appending to the experiment's `NOTEBOOKS.md` section. Always check `experiments/guides/` during iteration. The per-experiment plan + notebook sections are the full and only record — there is no global experiment log.
5. **Conclude** — `CONCLUSIONS.md` holds user-specified important conclusions. Never write to it directly — added collaboratively after discussion.

## CI

Before pushing, check CI locally:

```bash
./bin/run ruff check tests experiments
./bin/run ruff format --check tests experiments
./bin/run pytest
```

(Add `src` to the ruff targets once the package exists.)
