#!/bin/bash
#SBATCH --job-name=bfgs_fc
#SBATCH --output=logs/bfgs_fc_%j.out
#SBATCH --error=logs/bfgs_fc_%j.err
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=64
#SBATCH --time=00:45:00
#SBATCH --mem=120G

#SBATCH --uenv=prgenv-gnu/25.6:v2
#SBATCH --view=default

SCRIPT_DIR="${SCRIPT_DIR}"

export HDF5_USE_FILE_LOCKING=FALSE
export HDF5_MPI_OPT_TYPES=1
export ROMIO_FCNTL_LOCKW=0
export PYTHONWARNINGS="ignore:ResourceWarning"

mkdir -p logs

# Map the exported TASK_ID to the variable your Python script expects
export SLURM_ARRAY_TASK_ID=$TASK_ID

srun "${VENV_PATH}/bin/python" "${SCRIPT_DIR}/bfgs_and_fc.py"
