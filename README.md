# MatterSim-Phonopy-QHA Workflow

This repository contains a suite of scripts designed to automate thermodynamic properties of materials, using [**MatterSim-v1.0.0-5M**](https://github.com/microsoft/mattersim) for geometry optimization and force constant calculations, integrated with [**Phonopy**](https://phonopy.github.io/phonopy/qha.html) for Quasi-Harmonic Approximation (QHA).

## 🛠 Installation

### 1. Preliminary Check (CSCS Alps)
Ensure you have the `critic2` image:
```bash
uenv image ls | grep critic2/1.2:1952527021
# If missing, pull it:
uenv image pull critic2/1.2:1952527021
```

### 2. Environment setup ###

Following the [CSCS Python Guide](https://docs.cscs.ch/build-install/python/#installing-venv-on-top-of-a-uenv-view "Go to CSCS Documentation"):

```bash
uenv start --view=default prgenv-gnu/25.6:v2
unset PYTHONPATH
export PYTHONUSERBASE="$(dirname "$(dirname "$(which python)")")"

# Create Virtual Environment
uv venv --python 3.12 --system-site-packages --seed --relocatable --link-mode=copy path/to/my-venv-phonopy-mattersim
source path/to/my-venv-phonopy-mattersim/bin/activate

# Install Dependencies
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install mace-torch mattersim phonopy

# Deactivate venv and uenv 
deactivate
exit
```


## 🚀 How to Use

### 1. Prepare your Workspace
1. **Clone the repository** into your `$STORE` or `$PROJECT` directory.
2. **Navigate to `$SCRATCH`** and create a dedicated run directory for your simulation.
3. **Copy your structure file** (e.g., `.xyz`, `.cif`, or extended `xyz`) and the `master.sh` script into this run directory.
   > **Note:** Ensure the lattice vectors are explicitly specified in your structure file.

### 2. Configure `master.sh`
Open `master.sh` in a text editor and update the following variables to match your environment:

* `SCRIPT_DIR`: The full path to the directory where you cloned this repository.
* `VENV_PATH`: The path to the virtual environment created during the **Installation** step.
* `NUM_VOLUMES`: The number of volume points for the QHA calculation (Default is `21`, which creates volumes equally spaced from `0.9` to `1.1` of the original volume).

### 3. Execution
Once you have configured the paths in `master.sh`, submit the job to the Slurm scheduler:

```bash
sbatch master.sh
```
## 📊 Results & Output

The `master.sh` script coordinates the execution of the sub-scripts. It will automatically create a directory for each volume increment, named according to the volume scale (e.g., `vol_0.900`, `vol_1.000`, `vol_1.100`).

### 📂 Inside Each Volume Folder (`vol_*/`)
Each folder contains the specific data for that volume point:

* **Optimization:**
    * `opt.log`: Log of the geometry optimization at constant volume.
    * `POSCAR`: Optimized structure in VASP format (required for thermal properties).
* **Physics Data:**
    * `energy_volume.dat`: Final energy and volume pair used for the Equation of State (EOS) fit.
    * `force_constants.hdf5`: The force constants calculated by MatterSim.
* **Phonopy Specifics:**
    * `phonopy.conf`: Configuration details for the run.
    * `thermal_properties.yaml` & `phonopy.yaml`: Main output files containing phonon data.
    * `phonopy.out`: Standard output log.

### 📂 In the Parent Directory (QHA Results)
After the volume-specific tasks finish, `run_qha.sh` aggregates the data to produce the final Quasi-Harmonic Approximation results.

| Property Category | Resulting Files |
| :--- | :--- |
| **Temperature Dependence** | `volume-temperature.dat`, `thermal_expansion.dat`, `gruneisen-temperature.dat` |
| **Thermodynamics** | `gibbs-temperature.dat`, `helmholtz-volume.dat`, `helmholtz-volume_fitted.dat` |
| **Heat Capacity** | `Cp-temperature.dat`, `Cp-temperature_polyfit.dat`, `Cv-volume.dat` |
| **Elasticity** | `bulk_modulus-temperature.dat`, `dsdv-temperature.dat`, `entropy-volume.dat` |

---

## 🔬 Methodology
The geometry optimization and force constants are calculated using **MatterSim-v1.0.0-5M**. 

As shown in [Nature Communications (2025)](https://www.nature.com/articles/s41524-025-01650-1), this model provides state-of-the-art performance for phonon properties when compared against other machine learning potentials.
