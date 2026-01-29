#!/bin/bash
# install.sh - Automated setup for CSCS Alps

set -e  

echo "Starting installation..."

# 1. Setup Python environment variables
unset PYTHONPATH
export PYTHONUSERBASE="$(dirname "$(dirname "$(which python)")")"

# 2. Create Virtual Environment
echo "Creating virtual environment..."
uv venv --python 3.12 --system-site-packages --seed --relocatable --link-mode=copy venv_mattersim_phonopy-qha
. venv_mattersim_phonopy-qha/bin/activate

# 3. Install Dependencies
echo "pip: Installing packages..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install mace-torch mattersim phonopy

echo "Installation complete!
