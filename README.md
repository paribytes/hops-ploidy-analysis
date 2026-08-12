# Hops Ploidy Analysis

K-mer based ploidy estimation for *Humulus lupulus* samples using KMC and GenomeScope2.

## Overview

This pipeline estimates ploidy, homozygosity, and heterozygosity for 192 *H. lupulus* samples
across two HPC clusters using k-mer frequency profiling.

## Tools

- **KMC v3.2.4** — k-mer counting from paired-end Illumina reads
- **GenomeScope2 v2.0** — genome profiling and ploidy modeling (k=21, p=2)

## Pipeline

1. K-mer counting per sample using KMC (k=21)
2. K-mer histogram generation
3. Genome profiling with GenomeScope2 (p=2)
4. Summary table aggregation across all samples

## Repository Structure

- `scripts/` — job submission and aggregation scripts
- `results/` — per-batch TSV summary tables
- `docs/` — methods notes and caveats

## Environment Setup

All tools were run within a conda environment. To reproduce:

```bash
conda create -n genomescope_env python=3.10 -y
conda activate genomescope_env

# Install KMC
# Download precompiled binary from https://github.com/refresh-bio/KMC/releases
# KMC v3.2.4 linux x64 binary was used

# Install GenomeScope2 R dependencies
conda install -c conda-forge r-base=4.2 -y
R -e 'install.packages(c("argparse", "minpack.lm"), repos="https://cran.r-project.org")'

# Clone and install GenomeScope2
git clone https://github.com/tbenavi1/genomescope2.0.git
cd genomescope2.0 && Rscript install.R

# Add GenomeScope2 to PATH
export PATH=/path/to/genomescope2.0:$PATH

# Install smudgeplot dependencies and smudgeplot
conda install -c conda-forge numpy pandas matplotlib -y
pip install smudgeplot --no-deps
```

### Notes
- KMC was installed as a precompiled binary due to glibc version constraints on the clusters
- GenomeScope2 requires Rscript to be in PATH — activate the conda environment before running
- Smudgeplot v0.5.3 was installed but ultimately not used due to insufficient sequencing 
  coverage (~15-20x) for reliable heterozygous k-mer pair detection

## Cluster Setup

This analysis was run across two institutional HPC clusters with different job schedulers:

- **Cluster 1 (PBS/Torque)** — 40 samples; job script: `scripts/kmc_genomescope_array_pbs.pbs`
- **Cluster 2 (SLURM)** — 164 samples; job script: `scripts/kmc_genomescope_array_slurm.slurm`

Both scripts run the same pipeline (KMC → histogram → GenomeScope2) but differ in scheduler
syntax (`#PBS` vs `#SBATCH`), array task variable (`PBS_ARRAYID` vs `SLURM_ARRAY_TASK_ID`),
and resource request format. The conda environment (`genomescope_env`) was set up independently
on each cluster using miniconda3/miniforge3.

## Key Findings

- Majority of samples consistent with diploidy (homozygosity ~89-96%, heterozygosity ~5-9%)
- Samples with genome size estimates < ~200 Mb flagged as potential polyploids
- Samples with genome size estimates > ~950 Mb flagged for further inspection
- Absolute genome size estimates (~550-780 Mb) are lower than the published haploid size
  (~2.5 Gb for *H. lupulus*), likely an artifact of high repeat content (~78-84%) and
  moderate sequencing depth

## Caveats

Heterozygosity estimates and relative genome size comparisons between samples remain
interpretable for ploidy inference despite the absolute size underestimation.

