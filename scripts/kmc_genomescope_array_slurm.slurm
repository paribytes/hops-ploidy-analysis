#!/bin/bash
#SBATCH --job-name=ploidy_array
#SBATCH --partition=debug
#SBATCH --array=1-164%20
#SBATCH --cpus-per-task=4
#SBATCH --time=30:00:00
#SBATCH --output=/raid600/home/priyanshi/projects/ploidy_analysis/logs/ploidy_%A_%a.log

source ~/.bashrc
conda activate /home/priyanshi/miniconda3/envs/genomescope_env

BASE=/usr/scratchH/shared/HOP-BATCH1
OUTDIR=/raid600/home/priyanshi/projects/ploidy_analysis
SAMPLE_LIST=${OUTDIR}/sample_list.txt

mkdir -p ${OUTDIR}/kmer_counts ${OUTDIR}/tmp_kmc ${OUTDIR}/genomescope_out ${OUTDIR}/logs

# get this array task's sample name (1-indexed, matches SLURM_ARRAY_TASK_ID)
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLE_LIST})

echo "Processing sample: $sample (array task: ${SLURM_ARRAY_TASK_ID})"

mkdir -p ${OUTDIR}/tmp_kmc/${sample}

# Step 1: KMC — file list across all 4 lanes for this sample
ls ${BASE}/${sample}/${sample}_*_R1.fastq.gz ${BASE}/${sample}/${sample}_*_R2.fastq.gz \
    > ${OUTDIR}/kmer_counts/${sample}_files.txt

kmc -k21 -t4 -m12 -ci1 -cs10000 \
    @${OUTDIR}/kmer_counts/${sample}_files.txt \
    ${OUTDIR}/kmer_counts/${sample} \
    ${OUTDIR}/tmp_kmc/${sample}/

kmc_tools transform ${OUTDIR}/kmer_counts/${sample} \
    histogram ${OUTDIR}/kmer_counts/${sample}.hist -cx10000

# Step 2: GenomeScope2 at p=2
genomescope.R \
    -i ${OUTDIR}/kmer_counts/${sample}.hist \
    -o ${OUTDIR}/genomescope_out/${sample}_p2 \
    -k 21 -p 2

echo "Finished: $sample"