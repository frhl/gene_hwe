#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=var_hwe
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/var_hwe.log
#SBATCH --error=logs/var_hwe.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1
#SBATCH --array=21

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly bash_script="scripts/_var_hwe.sh"
readonly rscript="scripts/_var_hwe.R"
readonly curwd=$(pwd)

readonly cluster=$( get_current_cluster )
readonly array_idx=$( get_array_task_id )
readonly chr=$( get_chr ${array_idx} )

submit_hwe_job()
{
  local count_path=${1}
  local out_prefix=${2}
  local jname="_c${chr}_var_hwe"
  local lname="logs/_var_hwe"
  local project="lindgren.prj"
  local queue="short"
  local nslots="1"
  local num_lines=$( zcat ${count_path} | wc -l )
  local num_chunks=$(( (${num_lines} + ${chunk_size} - 1) / ${chunk_size} ))
  local array_chunks="1-${num_chunks}"
  local slurm_jid=$(sbatch \
    --account="${project}" \
    --job-name="${jname}" \
    --output="${lname}.log" \
    --error="${lname}.errors.log" \
    --chdir="${curwd}" \
    --partition="${queue}" \
    --cpus-per-task="${nslots}" \
    --array=${array_chunks} \
    --parsable \
    "${bash_script}" \
    "${rscript}" \
    "${count_path}" \
    "${chunk_size}" \
    "${num_chunks}" \
    "${out_prefix}")

}

readonly counts_dir="data/gnomad/subset"
readonly counts_prefix="gnomad.exomes.v4.0.sites.chr${chr}.counts.all"
readonly chunk_size=1000

readonly out_dir="data/gnomad/var_hwe_p"
mkdir -p ${out_dir}

for pop in "nfe"; do
  for anno in "pLoF" "synonymous" "damaging_missense" "other_missense" "non_coding"; do
    submit_hwe_job "${counts_dir}/${counts_prefix}.${pop}.${anno}.txt.gz" "${out_dir}/${counts_prefix}.${pop}.${anno}.hwe"
  done
done










