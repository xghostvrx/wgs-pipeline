#!/bin/bash

#SBATCH --job-name=kneaddata
#SBATCH --mail-user=gtesto@tgen.org
#SBATCH --mail-type=END,FAIL
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=5G
#SBATCH --time=48:00:00

# Initate bash shell using conda
source ~/.bashrc

# Activate kneaddata conda environment
conda activate kneaddata-0.7.4

# Create output folder
mkdir reports/kneaddata

cd ../reads/${SAMPLE_TYPE}

# Run kneaddata on available sequence reads
if [ FRAGMENT_TYPE="paired" ]; then
  for i in *_R1_*.fastq.gz
  do
      filename=$(basename "$i");
      fname="${filename%%_*.fastq.gz}";
      barcode="$(echo "$filename" | sed -e "s/${fname}_\(.*\)_L.*/\1/")";
      lane="$(echo "$filename" | sed -e "s/${fname}_${barcode}_\(.*\)_R.*/\1/")";
      direction="$(echo "$filename" | sed -e "s/${fname}_${barcode}_${lane}_\(.*\)_0.*/\1/")";
      set="$(echo "$filename" | sed -e "s/${fname}_${barcode}_${lane}_${direction}_\(.*\).fastq.gz*/\1/")";
      kneaddata \
        --input ${fname}_${barcode}_${lane}_R1_${set}.fastq.gz \
        --input ${fname}_${barcode}_${lane}_R2_${set}.fastq.gz \
        --trimmomatic /labs/Microbiome/gtesto/miniconda3/envs/kneaddata-0.7.4/share/trimmomatic-0.39-2 \
        --trimmomatic-options="ILLUMINACLIP:/scratch/gtesto/adapters/illumina_adapters_DNA.fasta:2:25:10 SLIDINGWINDOW:4:15 MINLEN:100" \
        --reference-db ${KNEADDATADB} \
        --max-memory 40g -p 8 -t 8 --output-prefix ${fname} \
        --output ${ROOT}${PROJECT_NAME}/${SAMPLE_TYPE}/results
  done
elif [ FRAGMENT_TYPE="single"]; then
  for i in *_R1_*.fastq.gz
  do
    filename=$(basename "$i")
    fname="${filename%%_*.fastq.gz}"
    barcode="$(echo "$filename" | sed -e "s/${fname}_\(.*\)_L.*/\1/")";
    lane="$(echo "$filename" | sed -e "s/${fname}_${barcode}_\(.*\)_R.*/\1/")";
    direction="$(echo "$filename" | sed -e "s/${fname}_${barcode}_${lane}_\(.*\)_0.*/\1/")";
    set="$(echo "$filename" | sed -e "s/${fname}_${barcode}_${lane}_${direction}_\(.*\).fastq.gz*/\1/")";
    kneaddata \
      --input ${fname}_${barcode}_${lane}_R1_${set}.fastq.gz \
        --trimmomatic-options="ILLUMINACLIP:/scratch/gtesto/adapters/illumina_adapters_DNA.fasta:2:25:10 SLIDINGWINDOW:4:15 MINLEN:100" \
        --reference-db ${KNEADDATADB} \
        --max-memory 40g -p 8 -t 8 --output-prefix ${fname} \
        --output ${ROOT}${PROJECT_NAME}/${SAMPLE_TYPE}/results
  done
fi

cd ../../${SAMPLE_TYPE}

# Output kneaddata report
kneaddata_read_count_table --input results --output reports/kneaddata/reads_report.kneaddata

# Deactivate kneadddata conda environment
conda deactivate

# Clean up file structure
cd results

mkdir homo_sapien
mkdir trimmomatic
mkdir unmatched
mkdir logs

mv *Homo_sapiens* homo_sapien/.
mv *trimmed* trimmomatic/.
mv *unmatched* unmatched/.
mv *log logs/.

if [ FRAGMENT_TYPE="paired" ]; then

  mkdir paired
  mv *paired* paired/.

elif [ FRAGMENT_TYPE="single"]; then

  mkdir single
  mv *.fastq single/

fi

cd ..
