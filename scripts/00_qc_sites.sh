#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=qc_sites
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/qc_sites.log
#SBATCH --error=logs/qc_sites.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 4
#SBATCH --array=21

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly rscript="scripts/00_qc_sites.R"
readonly task_id=$( get_array_task_id )
readonly chr=$( get_chr ${task_id} )

readonly in_dir="/well/lindgren/flassen/ressources/gnomad/exomes"
readonly in_file="${in_dir}/gnomad.exomes.v4.0.coverage.summary.tsv.gz"

readonly out_dir="data/gnomad/coverage"
readonly out_prefix="${out_dir}/gnomad.exomes.v4.0.sites.keep"

mkdir -p ${out_dir}

module load R
Rscript ${rscript} \
  --input_path="${in_file}" \
  --out_prefix="${out_prefix}"









