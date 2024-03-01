#!/usr/bin/env bash

#SBATCH --account=lindgren.prj
#SBATCH --job-name=process_csqs
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/process_csqs.log
#SBATCH --error=logs/process_csqs.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1
#SBATCH --array=1-22

set -o errexit
set -o nounset

source utils/qsub_utils.sh
source utils/hail_utils.sh

readonly spark_dir="data/tmp/spark"

readonly array_idx=$( get_array_task_id )
readonly chr=$( get_chr ${array_idx} )

readonly in_dir="data/gnomad/exomes/vep105/vep_out"
readonly in="${in_dir}/gnomad.exomes.v4.0.chr${chr}.vep105.ht"

readonly out_dir="data/gnomad/exomes/vep105/process_csqs"
readonly out_prefix="${out_dir}/gnomad.exomes.v4.0.chr${chr}.vep105.csqs"
readonly hail_script="scripts/gnomad/03_process_csqs.py"

mkdir -p ${out_dir}
mkdir -p ${spark_dir}

if [ ! -f "${out_prefix}_vep.ht/_SUCCESS" ]; then
  set_up_hail 0.2.97
  set_up_vep105
  set_up_pythonpath_legacy
  python3 ${hail_script} \
       --input_path "${in}" \
       --out_prefix "${out_prefix}"
else
  >&2 echo "${out_prefix}* already exists."
fi

