#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=subset_counts
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/subset_counts.log
#SBATCH --error=logs/subset_counts.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1
#SBATCH --array=21

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly rscript="scripts/01_subset_count.R"
readonly task_id=$( get_array_task_id )
readonly chr=$( get_chr ${task_id} )

readonly pop="nfe"
readonly in_dir="data/gnomad/counts"
readonly in_file="${in_dir}/gnomad.exomes.v4.0.sites.chr${chr}.counts.all.txt.gz"

readonly vep_dir="data/gnomad/exomes/vep105/worst_csqs"
readonly vep_path="${vep_dir}/gnomad.exomes.v4.0.chr${chr}.vep105.csqs.csqs.worst_csq_by_gene_canonical.brava_s50.txt.gz"

readonly out_dir="data/gnomad/subset"
readonly out_prefix="${out_dir}/gnomad.exomes.v4.0.sites.chr${chr}.counts.all.${pop}"

readonly AN_cutoff=10000
readonly AC_cutoff=1

mkdir -p ${out_dir}

module load R
Rscript ${rscript} \
  --input_path="${in_file}" \
  --vep_path="${vep_path}" \
  --population="${pop}" \
  --out_prefix="${out_prefix}" \
  --AN_cutoff=${AN_cutoff} \
  --AC_cutoff=${AC_cutoff}









