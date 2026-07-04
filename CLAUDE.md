# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Read these for context — don't restate them here:

- `instructions/` — externally provided project instructions (the spec /
  prototype, later handoffs). Files are named `NN_<slug>.md` in arrival order;
  read all of them, in numeric order. See `instructions/README.md`.

Layout:

- **`src/<pkg>/`** — core library (package name and submodules set by the project spec)
- **`experiments/`** — `# %%` cell-style Python scripts with config-at-top pattern
- **`gcp/`** — Cloud TPU lifecycle scripts (provision / run / pull / teardown)
- **`tests/`** — pytest tests

**Framework: PyTorch + torch_xla** (TPU). torch_xla is Linux/TPU-only and
installed on the VM by `gcp/bootstrap.sh` (not in `pyproject.toml`, so the
lockfile stays cross-platform). Work proceeds in iterations (defined by the
project spec in `instructions/`); per-experiment state lives in
`experiments/PLANS.md` + `experiments/NOTEBOOKS.md` (one `# EXP<NNN>` section
each).

## Environment

**Run everything via `./bin/run`:** `./bin/run python ...`, `./bin/run pytest`, `./bin/run ruff check tests experiments`. The wrapper sources `.env` and prepends `$REPO_DIR/.venv/bin/` to PATH, then execs. Never call bare `python` or `uv run` for execution — bare `python` lacks env vars / wrong interpreter.

**The repo runs in two places, each with its own `.env` and `.venv`:** your laptop (orchestration, analysis, CI parity) and the ephemeral TPU VM (compute). On the laptop `DEVICE=cpu` (or blank); on the VM `DEVICE=tpu`. `gcp/bootstrap.sh` writes a VM-appropriate `.env` at provision time.

**For dependency management** (`uv add`/`uv remove`/`uv sync`/`uv lock`): run on your laptop, then commit `uv.lock`. The VM installs from the lockfile (`uv sync --frozen`) via `gcp/bootstrap.sh`. It's a src-layout package (hatchling; package name set by the project spec). torch_xla is added on the VM by `bootstrap.sh`, not tracked in `pyproject.toml`.

## Cloud TPU — how compute works

**The TPU is disposable; durable state lives in GCS.** Never keep important data on the TPU VM — its disk is destroyed when the VM is deleted.

- **Provision per run, delete when idle.** `gcp/create.sh` (Spot + queued resource by default) → `gcp/launch.sh <script>` → `gcp/teardown.sh`. Nothing runs 24/7.
- **Durable store:** `gs://dis-2026-zw499-tpu-store` (region `us-east5`, in the user's `myloop-2026` project). The course project `dis-2026-tpu-zw499` is **compute only** — no buckets there.
- **Checkpoints write straight to GCS** (`$CKPT_DIR`), so a deleted/preempted Spot TPU costs only a resume. Make training resumable: save every ~15–30 min and restore the latest checkpoint on start.
- **Artifacts:** stage to `$ARTIFACT_DIR` on the VM, synced to `$GCS_ARTIFACTS`; `gcp/pull.sh` brings them to `./artifacts` locally for inspection / committing.
- Full lifecycle + cross-project auth: `gcp/README.md`.

## Code Style

- Ruff for linting and formatting (configured in `pyproject.toml`)
- Line-length 100, target Python 3.11
- Uses `from __future__ import annotations` throughout

## Experiment Outputs

Each experiment saves under `$ARTIFACT_DIR/exp_NNN/` (synced to GCS) and checkpoints under `$CKPT_DIR/exp_NNN/` (GCS).

- **Plots:** concise and highly informative — minimal clutter, clear labels, one takeaway per figure. Use Plotly and save as HTML (`fig.write_html()`); **also dump PNGs** so they can be read directly (see `experiments/guides/HP_SWEEP.md`).
- **Logging (printed output):** comprehensive — include all key numbers; use table format where possible.
- **Checkpoints:** always save `best` and `final` (when applicable), to GCS.

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
