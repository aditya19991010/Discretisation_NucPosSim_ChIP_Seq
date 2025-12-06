#!/bin/bash

inpdir="/home/aditya/epi_data_explore/PTM_explore_GSE202247/01_Data/processed/"
outdir="/home/aditya/epi_data_explore/PTM_explore_GSE202247/01_Data/processed/split_data"

mkdir -p "$outdir"

for i in "${inpdir}"/*narrowPeak; do
    name=$(basename "$i" .narrowPeak)
    subdir="$outdir/$name"
    mkdir -p "$subdir"

    awk -v out="$subdir" -v name="$name" '{print > out"/"name"_"$1".bed"}' "$i"
done

echo "All files are processed"
