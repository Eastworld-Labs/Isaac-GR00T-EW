# Running G1 policy server and rollout (default apple example)

The default apple example uses the **PnPAppleToPlate** task with the finetuned checkpoint `nvidia/GR00T-N1.6-G1-PnPAppleToPlate`.

## One-time setup (simulation env)

From the project root, run once:

```bash
apt-get update
apt-get install libegl1-mesa-dev libglu1-mesa
bash gr00t/eval/sim/GR00T-WholeBodyControl/setup_GR00T_WholeBodyControl.sh
```

## 1. Start the G1 policy server

In one terminal (from project root):

```bash
uv run --extra=gpu python gr00t/eval/run_gr00t_server.py \
    --model-path nvidia/GR00T-N1.6-G1-PnPAppleToPlate \
    --embodiment-tag UNITREE_G1 \
    --use-sim-policy-wrapper
```

## 2. Run rollout

In a second terminal (from project root). Rollout defaults to the policy client at `localhost:5555` (no need to pass `--model_path`).

```bash
gr00t/eval/sim/GR00T-WholeBodyControl/GR00T-WholeBodyControl_uv/.venv/bin/python gr00t/eval/rollout_policy.py \
    --n_episodes 10 \
    --max_episode_steps=1440 \
    --env_name gr00tlocomanip_g1_sim/LMPnPAppleToPlateDC_G1_gear_wbc \
    --n_action_steps 20 \
    --n_envs 1
```

With on-screen GUI (G1 only):

```bash
gr00t/eval/sim/GR00T-WholeBodyControl/GR00T-WholeBodyControl_uv/.venv/bin/python gr00t/eval/rollout_policy.py \
    --n_episodes 10 \
    --max_episode_steps=1440 \
    --env_name gr00tlocomanip_g1_sim/LMPnPAppleToPlateDC_G1_gear_wbc \
    --n_action_steps 20 \
    --n_envs 1 \
    --show_gui
```

- `--n_episodes`: number of evaluation episodes  
- `--n_envs`: number of parallel environments  
- `--show_gui`: show on-screen GUI (G1 locomanip only)  
- Policy client defaults: `--policy_client_host localhost`, `--policy_client_port 5555`  
- Full details: [examples/GR00T-WholeBodyControl/README.md](examples/GR00T-WholeBodyControl/README.md)
