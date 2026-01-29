import torch
import h5py
import textwrap
import os
import time
import sys
import glob
import numpy as np
from mattersim.forcefield import MatterSimCalculator
from ase.io import read
from ase import Atoms
from ase.optimize import BFGS, FIRE, BFGSLineSearch
from ase.filters import FrechetCellFilter
from phonopy import Phonopy
from phonopy.structure.atoms import PhonopyAtoms
from phonopy.file_IO import write_force_constants_to_hdf5
from phonopy.harmonic.force_constants import symmetrize_force_constants, set_translational_invariance


# 1. Search for both .xyz and .cif files
input_files = glob.glob("*.xyz") + glob.glob("*.cif")

# 2. Validation logic
if len(input_files) == 1:
    input_file = input_files[0]
    print(f"Automatically detected input file: {input_file}")
elif len(input_files) == 0:
    print("Error: No .xyz or .cif file found in the current directory!")
    sys.exit(1)
else:
    # This catches cases with 2 xyz, 2 cif, or 1 of each
    print(f"Error: Multiple structure files found! {input_files}")
    print("Please ensure only one .xyz or .cif file is present.")
    sys.exit(1)


master_dir = os.getcwd()

# 1. Get the global number of volumes (default to 21 if not found)
num_vols = int(os.environ.get("NUM_VOLS", 21))

# should we change the possibility of going to other volumes % boundaries? i.e. more that 10% off the original one?
scales = np.linspace(0.90, 1.10, num_vols)

# 2. Get Task ID and assign the specific scale for this job
try:
    task_id = int(os.environ.get("SLURM_ARRAY_TASK_ID", 0))
except (TypeError, ValueError):
    task_id = 0

time.sleep(task_id*1)

s = scales[task_id]
folder = f"vol_{s:.3f}"

# 3. Create folder 
os.makedirs(folder, exist_ok=True)
os.chdir(folder)

print(f"--- Task {task_id} starting: Volume Scale {s:.3f} in folder {folder} ---")

calc = MatterSimCalculator(load_path="MatterSim-v1.0.0-5M.pth", device="cuda")


# 5. Load atoms from the master directory
atoms = read(os.path.join(master_dir, input_file))
atoms.calc = calc

# Apply scaling
atoms.set_cell(atoms.get_cell() * (s**(1/3)), scale_atoms=True)

# --- STEP 1: Internal Relaxation with FIXED VOLUME ---
filtered_atoms = FrechetCellFilter(atoms, constant_volume=True)

dyn = FIRE(filtered_atoms, logfile='opt.log')   # more robust than BFGS
dyn.run(fmax=0.0005)


# Write result for this specific volume
with open("energy_volume.dat", "w") as f:
    f.write(f"{atoms.get_volume():15.8f} {atoms.get_potential_energy():15.8f}\n")

#save to POSCAR: this is needed by phonopy to run later the thermal properties calculation

atoms.write("POSCAR", format="vasp")

# --- STEP 2: Phonopy ---
unitcell = PhonopyAtoms(symbols=atoms.get_chemical_symbols(),
                        positions=atoms.get_positions(),
                        cell=atoms.get_cell())

cell_of_original_atoms = atoms.get_cell()
lengths = [np.linalg.norm(v) for v in cell_of_original_atoms]

# to estimate supercell dimension, I impose a minimum lattice vector magnitude of 15Å along the periodic directions as in aiidalab vibroscopy app

dim = [int(np.ceil(15.0 / l)) for l in lengths]
dim_string = f"{dim[0]} {dim[1]} {dim[2]}"


phonon = Phonopy(unitcell, supercell_matrix=dim, primitive_matrix=np.eye(3), is_symmetry=True)
phonon.generate_displacements(distance=0.01)
supercells = phonon.supercells_with_displacements

# --- STEP 3: Forces ---
set_of_forces = []
for i, sc in enumerate(supercells):
    if sc is None: continue
    sc_ase = Atoms(symbols=sc.symbols,
                   scaled_positions=sc.scaled_positions,
                   cell=sc.cell, pbc=True)
    sc_ase.calc = calc
    set_of_forces.append(sc_ase.get_forces())
    if i % 50 == 0: torch.cuda.empty_cache()

# --- STEP 4: Save Force Constants ---
phonon.forces = set_of_forces
phonon.produce_force_constants()
fc = phonon.force_constants
symmetrize_force_constants(fc)
set_translational_invariance(fc)


filename = "force_constants.hdf5"

# Remove any existing/corrupted file first
if os.path.exists(filename):
    os.remove(filename)

# Use a try-except block for the HDF5 write
try:
    with h5py.File(filename, "w") as f:
        f.create_dataset("force_constants", data=fc, chunks=True)
except OSError as e:
    print(f"HDF5 Write Error: {e}")
    # Optional: Wait and try one more time
    time.sleep(10)
    with h5py.File(filename, "w") as f:
        f.create_dataset("force_constants", data=fc, chunks=True)


# Local config file that is needed later by "run_all_phonopy.sh" to run thermal properties

with open("phonopy.conf", "w") as f:
    f.write(textwrap.dedent(f"""\
        DIM = {dim_string}
        MESH = 20 20 20
        TMIN = 0.0
        TMAX = 1600.0
        TSTEP = 10
        TPROP = .True.
        WRITE_MESH=.False.
        SYMMETRY_TOLERANCE=1e-05
        HDF5 = .True.
        READ_FORCE_CONSTANTS = .True.
    """))

print(f"--- Task {task_id} Finished ---")

