#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=gene_hwe
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/gene_hwe.log
#SBATCH --error=logs/gene_hwe.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1
#SBATCH --array=1-22

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly rscript="scripts/04_gene_hwe.R"
readonly curwd=$(pwd)

readonly cluster=$( get_current_cluster )
readonly array_idx=$( get_array_task_id )
readonly chr=$( get_chr ${array_idx} )

readonly pop="nfe_non_ukb"
readonly maf_label="maf3"
readonly counts_dir="data/gnomad/genes/${pop}/${maf_label}"
readonly counts_prefix="gnomad.exomes.v4.0.genes.chr${chr}.counts.all.${pop}.${maf_label}"
readonly out_dir="data/gnomad/hwe/genes/${pop}/${maf_label}"

mkdir -p ${out_dir}

set_up_rpy
for pop in "non_ukb_nfe"; do
  for anno in "pLoF" "pLoF_damaging_missense" "synonymous"; do
    input_path="${counts_dir}/${counts_prefix}.${pop}.${anno}.txt.gz" 
    out_prefix="${out_dir}/${counts_prefix}.${pop}.${anno}.hwe"
    Rscript ${rscript} \
      --input_path ${input_path} \
      --out_prefix ${out_prefix}
  done
done











