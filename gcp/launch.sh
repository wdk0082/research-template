#!/usr/bin/env bash
# gcp/launch.sh <experiment.py> [args...] — run an experiment on the TPU.
#
# Pulls the latest committed code onto the VM, then runs the script through
# ./bin/run with DEVICE=tpu and the GCS checkpoint/artifact dirs injected as
# caller-overrides (they win over the VM .env). Output streams to your terminal.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require PROJECT_ID ZONE TPU_NAME GIT_REMOTE
[[ $# -ge 1 ]] || { echo "usage: gcp/launch.sh experiments/NNN_*.py [args...]" >&2; exit 1; }

REPO_NAME="$(basename "${GIT_REMOTE%.git}")"
REF="${GIT_REF:-main}"

# Sync the VM to the latest committed code (commit + push before launching).
tpu_ssh --command "cd \$HOME/$REPO_NAME && git fetch origin $REF && git checkout $REF && git pull --ff-only"

inject="DEVICE=tpu"
if use_bucket; then
    inject="$inject CKPT_DIR='gs://$GCS_BUCKET/checkpoints' GCS_ARTIFACTS='gs://$GCS_BUCKET/artifacts'"
fi

# Forward experiment knobs set inline (e.g. `DRY_RUN=1 gcp/launch.sh ...`);
# ssh does not carry the caller's env, so we splice any that are set into the
# command. Add per-project experiment knobs to this list as they appear.
# WANDB_* come from the laptop .env (sourced by lib.sh) so on-TPU NN training
# authenticates and logs online to your wandb account; the API key is spliced
# into the remote command, which is fine for an ephemeral personal VM.
for v in DRY_RUN \
         WANDB_API_KEY WANDB_MODE WANDB_PROJECT WANDB_ENTITY; do
    [[ -n "${!v:-}" ]] && inject="$inject $v='${!v}'"
done

echo "Launching on $TPU_NAME:  $*"
tpu_ssh --command "cd \$HOME/$REPO_NAME && PYTHONUNBUFFERED=1 $inject ./bin/run python -u $*"

# Bucket mode: checkpoints/artifacts are already durable in GCS.
# Local-pull mode: copy them back now, before the VM is gone.
if ! use_bucket; then
    echo "Local-pull mode: copying artifacts back…"
    "$GCP_DIR/pull.sh" || true
fi
