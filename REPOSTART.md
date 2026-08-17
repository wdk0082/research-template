# Repo Management Conventions

Standing conventions for how this repo is set up. Follow these when
scaffolding any missing piece.

## Python & Package Management

- **Python version:** 3.11, pinned in `.python-version`
- **Package manager:** [uv](https://docs.astral.sh/uv/) (not pip/conda)
- **Lockfile:** `uv.lock` checked into version control for reproducibility
- **Install:** `uv sync --all-groups` (local dev) or `uv sync --frozen` (CI / any other machine, never mutates lockfile)
- **Running scripts:** always `./bin/run python ...` or `./bin/run pytest`, never bare `python`
- **Packaging:** src-layout package built with hatchling (`[build-system]` +
  `[tool.hatch.build.targets.wheel]`). Package name set by the project
  instructions (see `instructions/`).

## Compute Framework

PyTorch by default (the project instructions may override the framework).
Write device-agnostic code: select the device from `$DEVICE` (`cuda` /
`mps` / `cpu`; blank = auto-detect) in one place and pass it around.
Platform-specific accelerator packages (e.g. `torch_xla` for TPU, ROCm
builds) stay **out of `pyproject.toml`** so the lockfile remains
cross-platform — install them per-machine and document how in the compute
backend's README.

## Virtual Environment

The venv lives at `$REPO_DIR/.venv` (repo root):

```bash
UV_PROJECT_ENVIRONMENT=$REPO_DIR/.venv   # default; only set if relocating
```

Same layout on every machine the repo runs on; each machine's `.venv` is
reproducible from the lockfile (`uv sync`).

## Environment Variables (.env)

- `.env` holds all runtime config (device, output paths, secrets). **Git-ignored.**
- `.env.example` is the committed template with empty/commented values.
- Load before any command: `set -a; source .env; set +a` (or just use `./bin/run`).
- If the repo runs on more than one machine (laptop + remote compute), each
  machine keeps its own `.env` derived from `.env.example` — `DEVICE` and
  the paths are the usual differences.

## Cache & Output Paths

Durable outputs go under env-var dirs (gitignored, local by default); heavy
caches can be pointed at a scratch disk:

| Env var | Purpose | Default / example |
| --- | --- | --- |
| `ARTIFACT_DIR` | per-experiment artifacts (plots, tables, logs) | `./artifacts` |
| `CKPT_DIR` | checkpoints | `./checkpoints` |
| `SCRATCH` | optional ephemeral root for caches | `$HOME/scratch` |
| `HF_HOME` | Hugging Face hub cache | `$SCRATCH/hf` |
| `WANDB_DIR` | W&B run files | `$SCRATCH/wandb` |
| `UV_CACHE_DIR` | uv download/build cache | `$SCRATCH/uv-cache` |

## Directory Layout

```text
pyproject.toml          # single source of deps + tool config
uv.lock                 # locked deps
.python-version         # pinned Python version
.env / .env.example     # env vars
instructions/           # externally provided instructions (specs, handoffs, briefs) — NN_<slug>.md
src/<pkg>/              # src-layout package (added once the project's instructions land)
configs/                # YAML configs
experiments/            # runnable `# %%` scripts + PLANS.md / NOTEBOOKS.md (per-experiment docs)
tests/                  # pytest tests
```

## External Instructions (`instructions/`)

Documents provided from outside the repo — project specs ("prototypes"),
research-line handoffs, task briefs, mid-project redirections — live in
`instructions/`, named `NN_<snake_case_slug>.md` in arrival order. Numbers
encode arrival order only, not a document's kind (the first file need not be
a spec); they are never reused or reshuffled. Treat the files as read-only
inputs: reference them in place (from `CLAUDE.md`, plans, notebooks), never
edit or fork them; where two conflict, the newer file wins. See
`instructions/README.md`.

## Linting & Formatting

- **Ruff** for both linting and formatting (configured in `pyproject.toml`)
  - line-length 100, target py311
  - Rule sets: E, F, I, W, UP, B, SIM, RUF (E501 ignored)
- No pre-commit hooks or Makefile; CI handles enforcement

## Third-Party Research Code

Vendored subsets of external research repos go in `third_party/<repo>/`. Each gets a `README.md` with source URL, commit hash, license, and what was taken. Rewrite instead when deep integration with our own abstractions is needed.

## Remote Compute (optional)

The template is local-first; add a remote backend only when a project needs
one. When you do, keep these invariants:

- **Compute is disposable; durable state lives in a durable store.** Never
  keep the only copy of checkpoints / artifacts / data on a remote machine —
  write to object storage (S3 / GCS / …) or sync back before teardown.
- **Provision per run, delete when idle.** Prefer cheap preemptible / spot
  instances; nothing runs 24/7.
- **Resumable training.** Assume preemption: checkpoint to `$CKPT_DIR`
  every ~15–30 min and restore the latest on start, so a killed machine
  costs only a resume.
- **Lifecycle scripts live in a backend dir** (`gcp/`, `slurm/`, `ssh/`, …)
  with their own README: create / bootstrap / launch / pull / status /
  teardown. They run on the laptop and read config from `.env`; the
  launcher injects machine-appropriate `DEVICE` / path overrides, which win
  over `.env` (see `bin/run`).
- **Per-machine `.env` + `.venv`**, both derived from the committed
  templates (`.env.example`, `uv.lock`) by the bootstrap script.
- **Never commit credentials.** Keys live under `keys/` (gitignored).

`tpu-research-template` is a worked example of this pattern for Google
Cloud TPU.

## .gitignore Essentials

Beyond the standard Python gitignore, these project-specific entries matter:

```text
.env                    # secrets
.venv                   # local venv
.cache/ outputs/ artifacts/ checkpoints/ screenshots/
keys/ *sa-key.json      # NEVER commit credentials
*.code-workspace .vscode/
```

## CI

- GitHub Actions workflow at `.github/workflows/ci.yml` runs: Ruff lint, Ruff format check, pytest
- Always check CI before pushing: `./bin/run ruff check tests experiments` and `./bin/run pytest` locally to replicate. Add `src` to the ruff targets once the package exists.
