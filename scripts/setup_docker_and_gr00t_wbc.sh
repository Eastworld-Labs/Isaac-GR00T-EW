#!/usr/bin/env bash
# Setup Docker and gr00t_wbc container.
# Run with: bash scripts/setup_docker_and_gr00t_wbc.sh
# Requires: sudo access, Ubuntu 22.04, NVIDIA GPU (for nvidia-container-toolkit).

set -e

# --- 1. Install Docker (if not present) ---
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "Docker installed. Add yourself to docker group to run without sudo: sudo usermod -aG docker $USER"
else
  echo "Docker already installed: $(docker --version)"
fi

# --- 2. Install NVIDIA Container Toolkit (for GPU in container) ---
if ! command -v nvidia-container-toolkit &>/dev/null 2>&1; then
  echo "Installing NVIDIA Container Toolkit..."
  distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
  [ -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg ] && sudo rm /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg || true
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  echo "NVIDIA Container Toolkit installed."
else
  echo "NVIDIA Container Toolkit already installed."
fi

# --- 3. Pull and tag gr00t_wbc Docker image ---
GR00T_WBC_REPO="$(cd "$(dirname "$0")/.." && pwd)/external_dependencies/GR00T-WholeBodyControl"
if [ ! -d "$GR00T_WBC_REPO" ]; then
  echo "Error: GR00T-WholeBodyControl not found at $GR00T_WBC_REPO. Run: git submodule update --init external_dependencies/GR00T-WholeBodyControl"
  exit 1
fi
cd "$GR00T_WBC_REPO"
echo "Installing gr00t_wbc Docker image from docker.io/nvgear/gr00t_wbc:latest ..."
./docker/run_docker.sh --install --root
echo "Done. To enter the container later: cd $GR00T_WBC_REPO && ./docker/run_docker.sh --root"
echo "To run as normal user (build image locally): ./docker/run_docker.sh --build"
