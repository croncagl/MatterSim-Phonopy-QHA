#!/bin/bash

SCRIPT_DIR=$1
JOB_NAME=$2
NUM_VOLS=$3

# Loop in the number of volumes
MAX_IDX=$((NUM_VOLS - 1))
for i in $(seq 0 $MAX_IDX)
do
   echo "Submitting job for scale index $i..."
   
   # Pass the index to the submission script using --export
   sbatch --job-name=$JOB_NAME --export=ALL,TASK_ID=$i,SCRIPT_DIR="$SCRIPT_DIR",NUM_VOLS="$NUM_VOLS",VENV_PATH="$VENV_PATH" ${SCRIPT_DIR}/run_single_bfgs_and_fc.sh
done
