#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=power_hwe
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/power_hwe.log
#SBATCH --error=logs/power_hwe.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly bash_script="scripts/_power_hwe.sh"
readonly rscript="scripts/05_power_hwe.R"

readonly curwd=$(pwd)
readonly out_dir="data/gnomad/hwe/power"

mkdir -p ${out_dir}

submit_hwe_power_job()
{

  local sample_size=${1}
  local current_k=${2}
  local alternative=${3}
  local sig_level=${4}
  local out_prefix=${5}
  local jname="_power_hwe_n${sample_size}_k${current_k}"
  local lname="logs/_power_hwe"
  local project="lindgren.prj"
  local queue="short"
  local nslots="1"
  local slurm_jid=$(sbatch \
    --account="${project}" \
    --job-name="${jname}" \
    --output="${lname}.log" \
    --error="${lname}.errors.log" \
    --chdir="${curwd}" \
    --partition="${queue}" \
    --cpus-per-task="${nslots}" \
    --parsable \
    "${bash_script}" \
    "${rscript}" \
    "${sample_size}" \
    "${current_k}" \
    "${alternative}" \
    "${sig_level}" \
    "${out_prefix}")
}


for alt in "greater"; do
  for sig in "0.05"; do
    for samples in "10000" "40000" "100000" "400000"; do
        lower_bound=$(echo "$samples * 0.001" | bc)
        upper_bound=$(echo "$samples * 0.10" | bc)
        for k_value_float in $(seq $lower_bound 500 $upper_bound); do 
          k_value=$(echo ${k_value_float} | awk '{print int($1+0.5)}')
          out_prefix="${out_dir}/sim_n${samples}_k${k_value}_a${sig}_${alt}"
          if [[ ! -f "${out_prefix}.txt" ]]; then
            submit_hwe_power_job ${samples} ${k_value} ${alt} ${sig} ${out_prefix}
          else
            >&2 echo "${out_prefix}.txt already exists. Skipping.."
          fi
        done
     done
  done
done






