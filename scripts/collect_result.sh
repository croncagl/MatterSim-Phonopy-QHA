#!/bin/bash

# collect e-v results from each folder into a single file e-v.dat that is needed later by phonopy-qha

echo "# Volume [A^3]    Energy [eV]" > e-v.dat

# Loop through the volume folders in numerical order and append data
for folder in $(ls -d vol_* | sort -V); do
    if [ -f "$folder/energy_volume.dat" ]; then
        cat "$folder/energy_volume.dat" >> e-v.dat
    fi
done


# Create the folder list using the same sorted order
ls -d vol_*/ | sort -V > folder_list.txt

echo "Combined e-v.dat and folder_list.txt created successfully."
