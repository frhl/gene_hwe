#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=get_worst_csqs
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/wgs_ko_ukbb
#SBATCH --output=logs/get_worst_csqs.log
#SBATCH --error=logs/get_worst_csqs.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 2
#SBATCH --array=21

source utils/qsub_utils.sh
source utils/hail_utils.sh

readonly spark_dir="data/tmp/spark"

readonly array_idx=$( get_array_task_id )
readonly chr=$( get_chr ${array_idx} )

readonly in_dir="data/gnomad/genomes/vep105/process_csqs"
readonly in="${in_dir}/gnomad.genomes.v4.0.chr${chr}.vep105.csqs.ht"

readonly spliceai_dir="/well/lindgren/barney/brava_annotation/data/spliceai"
readonly spliceai_path="${spliceai_dir}/ukb_wes_450k.spliceai.chr${chr}.ht"

readonly revel_cutoff=0.773
readonly spliceai_cutoff=0.50 # 0.20/0.50
readonly case_builder="brava" # original/brava
readonly group="brava_s50"

readonly out_dir="data/gnomad/genomes/vep105/worst_csqs"
readonly out_prefix="${out_dir}/gnomad.genomes.v4.0.chr${chr}.vep105.csqs.csqs.worst_csq_by_gene_canonical.${group}"
readonly hail_script="scripts/gnomad/04_get_worst_csqs.py"

mkdir -p ${out_dir}
mkdir -p ${spark_dir}

set_up_hail 0.2.97
set_up_pythonpath_legacy
python3 ${hail_script} \
     --vep_path "${in}" \
     --case_builder "${case_builder}" \
     --spliceai_path "${spliceai_path}" \
     --spliceai_score "${spliceai_cutoff}" \
     --revel_score "${revel_cutoff}" \
     --out_prefix "${out_prefix}"

