#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=get_worst_csqs_iter
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/get_worst_csqs_iter.log
#SBATCH --error=logs/get_worst_csqs_iter.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1
#SBATCH --array=1-22

source utils/qsub_utils.sh
source utils/hail_utils.sh

readonly spark_dir="data/tmp/spark"
readonly hail_script="scripts/variant_annotation/04_get_worst_csqs.py"
mkdir -p ${spark_dir}

readonly array_idx=$( get_array_task_id )
readonly chr=$( get_chr ${array_idx} )

readonly in_dir="data/gnomad/exomes/vep105/process_csqs"
readonly in="${in_dir}/gnomad.exomes.v4.0.chr${chr}.vep105.csqs.ht"

readonly spliceai_dir="/well/lindgren/barney/brava_annotation/data/spliceai"
readonly spliceai_path="${spliceai_dir}/ukb_wes_450k.spliceai.chr${chr}.ht"


readonly cadd_cutoff=100 # not possible ensuring that only revel is used
readonly spliceai_cutoff=0.50 # 0.20/0.50
readonly case_builder="brava" # original/brava/non_synonmymous
#readonly revel_cutoff=0.2 #0.773

set_up_hail 0.2.97
set_up_pythonpath_legacy
for revel_cutoff in "0.1" "0.2" "0.3" "0.4" "0.5" "0.6" "0.7" "0.8" "0.9" ; do

  group="revel_${revel_cutoff}"
  out_dir="data/vep/worst_csqs_iter"
  out_prefix="${out_dir}/gnomad.exomes.v4.0.chr${chr}.vep105.csqs.csqs.worst_csq_by_gene_canonical.${group}"

  mkdir -p ${out_dir}

  if [[ ! -f "${out_prefix}.txt.gz" ]]; then
    python3 ${hail_script} \
         --vep_path "${in}" \
         --case_builder "${case_builder}" \
         --spliceai_path "${spliceai_path}" \
         --spliceai_score "${spliceai_cutoff}" \
         --revel_score "${revel_cutoff}" \
         --cadd_score "${cadd_cutoff}" \
         --out_prefix "${out_prefix}"
  fi

done



