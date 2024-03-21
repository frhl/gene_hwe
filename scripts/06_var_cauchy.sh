#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=var_cauchy
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/var_cauchy.log
#SBATCH --error=logs/var_cauchy.errors.log
#SBATCH --partition=epyc
#SBATCH --cpus-per-task 1
#SBATCH --array=21

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly rscript="scripts/06_var_cauchy.R"
readonly curwd=$(pwd)

readonly cluster=$( get_current_cluster )
readonly array_idx=$( get_array_task_id )
readonly chr=$( get_chr ${array_idx} )

readonly qc_id="median_dp30"
readonly maf_label="maf5"

set_up_rpy
for pop in "non_ukb_nfe"; do
  #for anno in "pLoF" "pLoF_damaging_missense" "synonymous"; do
  for anno in "pLoF"; do
    in_dir="data/gnomad/hwe/variants/${qc_id}/${pop}/${maf_label}"
    out_dir="data/gnomad/hwe/variants/${qc_id}/${pop}/${maf_label}"
    input_path="${in_dir}/gnomad.exomes.v4.0.sites.chr${chr}.counts.all.${qc_id}.${maf_label}.${pop}.${anno}.hwe.txt.gz"
    out_prefix="${out_dir}/gnomad.exomes.v4.0.sites.chr${chr}.counts.all.${qc_id}.${maf_label}.${pop}.${anno}.hwe.cauchy_by_gene"
    mkdir -p ${out_dir}
    Rscript ${rscript} \
      --input_path ${input_path} \
      --out_prefix ${out_prefix} \
      --pvalue_column "hwe_mid_p"
  done
done











