#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=vep
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/vep.log
#SBATCH --error=logs/vep.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 2
#SBATCH --array=1-19

set -o errexit
set -o nounset

source utils/qsub_utils.sh
source utils/hail_utils.sh

readonly spark_dir="data/tmp/spark"

readonly array_idx=$( get_array_task_id )
readonly chr=$( get_chr ${array_idx} )

readonly in_dir="data/gnomad/exomes/download"
readonly in="${in_dir}/gnomad.exomes.v4.0.sites.chr${chr}.vcf.bgz"

readonly json_path="/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/wes_ko_ukbb_nexus/utils/configs/vep105_revel_float.json"

readonly out_dir="data/gnomad/exomes/vep105/vep_out"
readonly out_prefix="${out_dir}/gnomad.exomes.v4.0.chr${chr}.vep105"

readonly hail_script="scripts/gnomad/02_vep.py"

mkdir -p ${out_dir}
mkdir -p ${spark_dir}

if [ ! -f "${out_prefix}_vep.ht/_SUCCESS" ]; then
  set_up_hail 0.2.97
  set_up_vep105
  set_up_pythonpath_legacy
  python3 ${hail_script} \
       --input_path "${in}" \
       --out_prefix "${out_prefix}" \
       --json_path "${json_path}"
else
  >&2 echo "${out_prefix}* already exists."
fi


