#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=to_gene
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/to_gene.log
#SBATCH --error=logs/to_gene.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1
#SBATCH --array=1-22

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly rscript="scripts/03_to_gene.R"
readonly task_id=$( get_array_task_id )
readonly chr=$( get_chr ${task_id} )

readonly subset="non_ukb" # all
readonly pop="non_ukb_nfe" # nfe
readonly in_dir="data/gnomad/counts"
readonly in_file="${in_dir}/gnomad.exomes.v4.0.sites.chr${chr}.counts.${subset}.txt.gz"

readonly qc_dir="data/gnomad/coverage"
readonly qc_path="${qc_dir}/gnomad.exomes.v4.0.sites.keep.txt.gz"

readonly vep_dir="data/gnomad/exomes/vep105/worst_csqs"
readonly vep_path="${vep_dir}/gnomad.exomes.v4.0.chr${chr}.vep105.csqs.csqs.worst_csq_by_gene_canonical.brava_s50.txt.gz"

readonly maf_label="maf5" # 10%
readonly out_dir="data/gnomad/genes/${maf_label}"
readonly out_prefix="${out_dir}/gnomad.exomes.v4.0.genes.chr${chr}.counts.all.${maf_label}.${pop}"

readonly maf_cutoff="0.1"
readonly AN_cutoff=10000
readonly AC_cutoff=1

mkdir -p ${out_dir}

module load R
Rscript ${rscript} \
  --input_path="${in_file}" \
  --vep_path="${vep_path}" \
  --qc_path="${qc_path}" \
  --population="${pop}" \
  --out_prefix="${out_prefix}" \
  --AN_cutoff=${AN_cutoff} \
  --AC_cutoff=${AC_cutoff} \
  --max_MAF_cutoff=${maf_cutoff}









