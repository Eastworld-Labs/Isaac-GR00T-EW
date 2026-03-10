#!/usr/bin/env bash
set -euxo pipefail

# Where this script lives (put it inside your repo)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_REPO="$SCRIPT_DIR/../../../.."
GR00T_WHOLEBODYCONTROL_REPO="$PROJECT_REPO/external_dependencies/GR00T-WholeBodyControl"
DECOUPLED_WBC_REPO="$GR00T_WHOLEBODYCONTROL_REPO/decoupled_wbc"
UV_ENV="$SCRIPT_DIR/GR00T-WholeBodyControl_uv"
WBC_STAGE_REPO="$UV_ENV/wbc_stage"

git submodule update --init $GR00T_WHOLEBODYCONTROL_REPO

# Build helpers
# python -m pip install cmake==3.18.4
rm -rf "$UV_ENV"
mkdir -p "$UV_ENV"
uv venv "$UV_ENV/.venv" --python 3.10
source "$UV_ENV/.venv/bin/activate"
uv pip install setuptools wheel

# # Sim stack
if ! command -v git-lfs >/dev/null 2>&1; then
    echo "Git LFS not installed. Please install: https://git-lfs.github.com/"
    exit 1
fi
git -C "$GR00T_WHOLEBODYCONTROL_REPO" lfs pull
if [ ! -d "$DECOUPLED_WBC_REPO" ]; then
    echo "Missing decoupled_wbc at $DECOUPLED_WBC_REPO"
    exit 1
fi

# setuptools now blocks readme paths outside package root (decoupled_wbc uses ../README.md).
# Install from a local staged copy so metadata resolves without mutating the submodule.
rm -rf "$WBC_STAGE_REPO"
mkdir -p "$WBC_STAGE_REPO"
cp -a "$DECOUPLED_WBC_REPO" "$WBC_STAGE_REPO/decoupled_wbc"
cp "$GR00T_WHOLEBODYCONTROL_REPO/README.md" "$WBC_STAGE_REPO/README.md"
cp "$GR00T_WHOLEBODYCONTROL_REPO/README.md" "$WBC_STAGE_REPO/decoupled_wbc/README.md"

# Keep staged package self-contained for setuptools path checks.
python - <<PY
from pathlib import Path

pyproject = Path("$WBC_STAGE_REPO/decoupled_wbc/pyproject.toml")
text = pyproject.read_text()
text = text.replace('readme = "../README.md"', 'readme = "README.md"')
pyproject.write_text(text)
print("Patched staged pyproject readme path:", pyproject)
PY

GIT_LFS_SKIP_SMUDGE=1 uv pip install -e "$WBC_STAGE_REPO/decoupled_wbc" --config-settings editable_mode=compat
uv pip install -e "$WBC_STAGE_REPO/decoupled_wbc/dexmg/gr00trobosuite" --config-settings editable_mode=compat
uv pip install -e "$WBC_STAGE_REPO/decoupled_wbc/dexmg/gr00trobocasa" --config-settings editable_mode=compat
uv pip install numpy==1.26.4 gymnasium==1.2.2 mujoco==3.2.6 transformers==4.51.3 matplotlib rerun-sdk==0.21.0 pin pin-pink onnxruntime msgpack==1.1.0 pyzmq==27.0.1

uv pip install --editable "$PROJECT_REPO" --no-deps

# Sanity import & env construction
python - <<'PY'
import os
os.environ.setdefault("MUJOCO_GL", "egl")
os.environ.setdefault("PYOPENGL_PLATFORM", "egl")
import gymnasium as gym, robocasa, robosuite
import gr00t.policy.server_client
import decoupled_wbc.control.envs.robocasa.sync_env
print("Imports OK:", robosuite.__version__)
env = gym.make("gr00tlocomanip_g1_sim/LMPnPAppleToPlateDC_G1_gear_wbc", enable_render=True)
print("Env OK:", type(env))
PY
