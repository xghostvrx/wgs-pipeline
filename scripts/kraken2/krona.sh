#!/bin/bash

#SBATCH --job-name=krona
#SBATCH --mail-user=gtesto@tgen.org
#SBATCH --mail-type=END,FAIL
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G
#SBATCH --time=00:01:00

# Initate bash shell using conda
source ~/.bashrc

# Activate krona conda environment
conda activate krona-2.8

# Create output folders
mkdir reports/krona
mkdir reports/krona/kraken2
mkdir reports/krona/bracken

cd reports/kraken2

# Generate krona using species reports from bracken
for i in *_report.kraken;
do
   filename=$(basename "$i");
   fname="${filename%_report.kraken}";
   python ${WGS}/scripts/dependencies/KrakenTools/kreport2krona.py -r ${filename} -o ../krona/kraken2/${fname}.krona;
done

ktImportText ../krona/kraken2/*.krona -o ../krona/kraken2.krona.html

cd bracken
for i in *_species_report.bracken;
do
   filename=$(basename "$i")
   fname="${filename%_species_report.bracken}";
   python ${WGS}/scripts/dependencies/KrakenTools/kreport2krona.py -r ${filename} -o ../../krona/bracken/${fname}.krona;
done

ktImportText ../../krona/bracken/*.krona -o ../../krona/bracken.krona.html

# Deactivate krona conda environment
conda deactivate

cd ../../../
