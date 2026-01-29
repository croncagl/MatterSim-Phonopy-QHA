#!/bin/bash
#SBATCH --job-name=master
#SBATCH --time=01:00:00
#SBATCH --partition=normal
#SBATCH --ntasks=1
#SBATCH --output=master_out_%j.log
#SBATCH --error=master_err_%j.log
#SBATCH --account=lp86


############# CHANGE HERE WHERE TO STORE THE SCRIPTS ####################
SCRIPT_DIR="$SCRATCH/path_to_scripts"
#########################################################################

############# CHANGE VENV PATH HERE #####################################
export VENV_PATH="path/to/my-venv-phonopy-mattersim"
#########################################################################

LOG_FILE="master_submission.log"

STRUC_ID=$(basename $(pwd))
BARRIER_NAME="bfgs_fc_${STRUC_ID}"

############# CHANGE THE NUMBER OF VOLUMES HERE #########################
NUM_VOLUMES=21
#########################################################################

echo "--- Submission Started for $STRUC_ID at: $(date) ---" > "$LOG_FILE"

# 1. Start Volume Calculations
echo "Submitting Volume Calculations..." | tee -a "$LOG_FILE"
bash ${SCRIPT_DIR}/run_all.sh "$SCRIPT_DIR" "$BARRIER_NAME" "$NUM_VOLUMES" >> "$LOG_FILE" 2>&1

# 2. Schedule Collection (Barrier)
echo "Scheduling Collection (Singleton: bfgs_fc)..." | tee -a "$LOG_FILE"
# We explicitly repeat the job name in sbatch to ensure singleton logic works
RAW_COLLECT=$(sbatch --parsable --job-name=$BARRIER_NAME --time=00:05:00 --dependency=singleton ${SCRIPT_DIR}/collect_result.sh)
COLLECT_ID=$(echo "$RAW_COLLECT" | cut -d';' -f1)
echo "Stage 2 ID: $COLLECT_ID" >> "$LOG_FILE"

# 3. Schedule Phonopy Post-processing: the number of jobs in the array is read from NUM_VOLUMES variable
echo "Scheduling Phonopy..." | tee -a "$LOG_FILE"
RAW_PHONO=$(sbatch --parsable --job-name="phono_${STRUC_ID}" --dependency=afterok:$COLLECT_ID --array=1-$NUM_VOLUMES ${SCRIPT_DIR}/run_all_phonopy.sh)
PHONO_ID=$(echo "$RAW_PHONO" | cut -d';' -f1)
echo "Stage 3 ID: $PHONO_ID" >> "$LOG_FILE"

# 4. Schedule QHA
echo "Scheduling QHA..." | tee -a "$LOG_FILE"
RAW_QHA=$(sbatch --parsable --job-name="qha_${STRUC_ID}" --dependency=afterok:$PHONO_ID ${SCRIPT_DIR}/run_qha.sh)
QHA_ID=$(echo "$RAW_QHA" | cut -d';' -f1)
echo "Stage 4 ID: $QHA_ID" >> "$LOG_FILE"

echo "--- All jobs scheduled ---" | tee -a "$LOG_FILE"
