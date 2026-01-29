# MatterSim-Phonopy-QHA Workflow

This repository contains a suite of scripts designed to automate thermodynamic properties of materials, using [**MatterSim-v1.0.0-5M**](https://github.com/microsoft/mattersim) for geometry optimization and force constant calculations, integrated with [**Phonopy**](https://phonopy.github.io/phonopy/qha.html) for Quasi-Harmonic Approximation (QHA).

## 🛠 Installation

### 1. Preliminary Check (CSCS Alps)
Ensure you have the `critic2` image available in your environment:
```bash
uenv image ls | grep critic2/1.2:1952527021
# If missing, pull it:
uenv image pull critic2/1.2:1952527021
```

### 2. Get the Code & Setup Environment ###

Clone the repository to a persistent location like your $PROJECT or $STORE directory and run the installation script.

```bash
# 1. Move to persistent storage and clone
cd $PROJECT  # or cd $STORE
git clone https://github.com/croncagl/MatterSim-Phonopy-QHA.git
cd MatterSim-Phonopy-QHA

# 2. Run the automated setup within the uenv
uenv start --view=default prgenv-gnu/25.6:v2
bash ./install.sh
```


## 🚀 How to Use

### 1. Prepare your Workspace
* **Navigate into your `$SCRATCH` directory** and create a dedicated run folder for your simulation.
* **Copy your structure file** (e.g., `.xyz`, `.cif`, or extended `xyz`) and the `master.sh` script into this run directory.
   > **Note:** Ensure the lattice vectors are explicitly specified in your structure file.

### 2. Configure `master.sh`
The script uses relative pathing to automatically find the supporting scripts and the virtual environment within your cloned repository folder.
You only need to open `master.sh` in a text editor if you wish to adjust the following:
* `NUM_VOLUMES`: The number of volume points for the QHA calculation (Default is `21`, which creates volumes equally spaced from `0.9` to `1.1` of the original volume).

### 3. Execution
Submit the job to the Slurm scheduler:

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
