#!/bin/bash -l
#SBATCH --job-name="phonopy_array"
#SBATCH --output=logs/err_%a.txt
#SBATCH --error=logs/err_%a.txt
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:30:00
#SBATCH --account=lp86
#SBATCH --uenv=critic2/1.2:1952527021
#SBATCH --view=default

mkdir -p logs

# 2. Get the folder name for THIS specific task from the list
# This reads the Nth line of folder_list.txt where N is the array ID
TARGET_DIR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" folder_list.txt)

# 3. Enter the folder and run
if [ -d "$TARGET_DIR" ]; then
    echo "Task ${SLURM_ARRAY_TASK_ID} processing folder: $TARGET_DIR"
    cd "$TARGET_DIR"
    
    /user-environment/env/default/bin/phonopy phonopy.conf > phonopy.out 2>&1
    
    cd ..
else
    echo "Folder $TARGET_DIR not found!"
    exit 1
fi
