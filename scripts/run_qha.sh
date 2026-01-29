#!/bin/bash -l
#SBATCH --no-requeue
#SBATCH --job-name="phonopy-qha_mace"
#SBATCH --get-user-env
#SBATCH --output=stdout_qha.txt
#SBATCH --error=stderr_qha.txt
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=262144

#SBATCH --hint=nomultithread
#SBATCH --no-requeue
#SBATCH --account=lp86

#SBATCH --time=00:15:00

#SBATCH --uenv=critic2/1.2:1952527021
#SBATCH --view=default

export OMP_NUM_THREADS=$((SLURM_CPUS_PER_TASK - 1))
export MPICH_GPU_SUPPORT_ENABLED=0
ulimit -s unlimited


/user-environment/env/default/bin/phonopy-qha --tmax=1650 e-v.dat vol_*/thermal_properties.yaml > phonopy_qha.out
