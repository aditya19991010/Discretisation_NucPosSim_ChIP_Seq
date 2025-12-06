#!/bin/bash

## base directory for the input files - subsetted bed files per gene
input_dir="/home/aditya/epi_data_explore/PTM_explore_GSE202247/01_Data/processed/split_data/"

## output parent directory for all gene-specific directories
output_parent_dir="/home/aditya/epi_data_explore/PTM_explore_GSE202247/01_Data/processed/H3K4me3_nucpos_results"

## Create the parent output directory if it doesn't exist
mkdir -p "$output_parent_dir"

## path to the NucPosSimulator directory - where NucPosSimulator has been downloaded
nucpossimulator_dir="/home/aditya/epi_data_explore/NucPosSimulator_linux64"  

## Ensure write permissions for the input directory and subdirectories
chmod -R u+w "$input_dir"

## Export variables and define the function for parallel execution
export nucpossimulator_dir output_parent_dir
run_simulator() {
    local bed_file="$1"
    local chr_id
    chr_id=$(basename "$bed_file" .bed)  # Keep _subset in gene_id(just a name)
    
    ## Create a directory for the gene inside the parent output directory
    local chr_dir="$output_parent_dir/$chr_id"
    mkdir -p "$chr_dir"
    
    ## Copy the gene's .bed file to its corresponding directory
    cp "$bed_file" "$chr_dir/"
    
    ## Navigate to the gene directory
    cd "$chr_dir" || exit
    
    ## Run NucPosSimulator in the gene's directory with the params.txt file
    "$nucpossimulator_dir/NucPosSimulator" "$chr_id.bed" "$nucpossimulator_dir/params.txt"
    
    ## Check if the NucPosSimulator ran successfully
    if [[ $? -ne 0 ]]; then
        echo "Error: NucPosSimulator failed for '$chr_id'."
    else
        echo "NucPosSimulator ran successfully for '$chr_id'."
    fi
}

## Export the function for use with GNU Parallel
export -f run_simulator

## Display the number of CPU cores being used
cpu='100'
echo "Using $cpu cores for parallel execution."

## Find all .bed files in the input directory
find "$input_dir" -type f -name "*chr*.bed" | parallel --jobs 100 --bar run_simulator {}

echo "NucPosSimulator completed for all chr subsets."

