# NucPosSimulator Processing Pipeline

This repository contains a small pipeline of shell and Python scripts to prepare ChIP-seq peak files, run NucPosSimulator per chromosome, round simulated BED coordinates, and discretise the results into a genome-wide binned matrix for a given histone modification.

## Overview

The pipeline is designed for yeast (sacCer3) ChIP-seq data in narrowPeak format and produces a per-bin 0/1 indicator of nucleosome occupancy for a specific modification.  The steps are:

1. Split input narrowPeak files into chromosome-specific BEDs.
2. Run NucPosSimulator on each chromosome BED in parallel.
3. Round the resulting BED coordinates to a fixed bin size (e.g. 200 bp).
4. Discretise the rounded BED intervals onto a pre-defined genome-wide binning scheme.

## Requirements

- [GNU Parallel](https://www.gnu.org/software/parallel/) (used in `02_run_nucpossimulator.sh`) 
- NucPosSimulator binary and `params.txt` in a directory such as `/path/to/NucPosSimulator_linux64`
- Python 3 with:
  - `pandas`
  - `numpy`
  - `joblib`
  - `tqdm`
  - `psutil` (imported but not currently used)

## Script 1: Split narrowPeak by chromosome

**File:** `01_chr_split.sh` 

This script takes all `*.narrowPeak` files in the input directory and splits each into per-chromosome BED files. Each chromosome-specific file is written into its own subdirectory.

- Input directory (edit as needed):
  - `inpdir="/home/aditya/epi_data_explore/PTM_explore_GSE202247/01_Data/processed/"`
- Output directory (created if missing):
  - `outdir="/home/aditya/epi_data_explore/PTM_explore_GSE202247/01_Data/processed/split_data"`

For each `sample.narrowPeak`, it creates a subdirectory `${outdir}/sample` and writes files of the form `sample_chrX.bed` based on the first column (chromosome) in the narrowPeak file.


## Script 2: Run NucPosSimulator per chromosome

**File:** `02_run_nucpossimulator.sh`

This script runs NucPosSimulator separately for each chromosome-specific BED file produced by script 1, using GNU Parallel.

- Input directory of per-chromosome BEDs:
  - `input_dir="/path/to/01_Data/processed/split_data/"`
- Parent output directory for all chromosome-specific runs:
  - `output_parent_dir="path/to/01_Data/processed/H3K4me3_nucpos_results"`
- NucPosSimulator directory:
  - `nucpossimulator_dir="path/to/NucPosSimulator_linux64"`

For each `*chr*.bed` file, it:

- Creates a directory `${output_parent_dir}/${chr_id}`.
- Copies the `.bed` file there.

Before running, ensure:
- `NucPosSimulator` and `params.txt` exist in `nucpossimulator_dir`.
- The number of jobs (`--jobs 100`) suits your hardware. 

## Script 3: Round NucPosSimulator BED coordinates

**File:** `03_round_off_result_bed_file.py`

This script rounds the start and end coordinates in NucPosSimulator output BED files to the nearest multiple of 200 bp (configurable by editing the helper function).

Assumptions:

- For each chromosome directory `${gene_dir}` under `base_directory`, there is a file:
  - `${gene_dir}.bed.result.bed`
- The script writes:
  - `${gene_dir}_rounded_result.bed`

Default base directory (edit as needed):



The script:

- Iterates over all subdirectories in `base_directory`.
- For each existing `*.bed.result.bed`, writes a 3-column BED with chromosome, rounded start, and rounded end.

## Script 4: Discretise rounded values into bins

**File:** `04_discretise_rounded_values.py`

This script maps the rounded BED intervals onto a genome-wide binned CSV and produces a binary column indicating presence (1) or absence (0) of the modification per bin.

Key configuration variables:

N_JOBS = 50 # Parallel jobs for joblib
CHUNK_SIZE = 50_000 # Rows per chunk when reading the bins CSV

MOD_FOLDER = '/path/to/01_Data/processed/H3K4me3_nucpos_results/'
MOD = 'H3K4me3_wt_x_peaks' # Prefix of per-chromosome result directories/files
MOD_COL = 'wt_xy_peaks' # Name of output column

BASE_PATH = '/path/to/NucPosSimulator_linux64'
Result_out = "path/to/03_Results/"



Expected columns in the bins CSV:

- `chr_id` (chromosome or region ID that matches directory suffixes used in `MOD`)
- `bin_start`
- `bin_end` 

For each chunk:

- Initialises `MOD_COL` to 0.
- For each `gene_id` (unique `chr_id` in the chunk), looks for:
{BASE_PATH}/{MOD_FOLDER}/{MOD}{gene_id}/{MOD}{gene_id}_rounded_result.bed

- If present, reads the start and end columns (cols 1 and 2, 0-based indexing) as integer positions.
- Sets `MOD_COL = 1` when `[bin_start, bin_end]` matches one of the BED start–end pairs.

At the end, it concatenates all chunks and writes:
{Result_out}/discretised_rounded_values_sacCer3_{MOD_COL}.csv

