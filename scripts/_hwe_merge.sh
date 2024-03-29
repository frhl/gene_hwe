#!/usr/bin/env bash

set -o errexit
set -o nounset

source utils/qsub_utils.sh
source utils/bash_utils.sh
source utils/vcf_utils.sh

readonly rscript="scripts/_hwe_merge.R"

readonly regex_prefix=${1?Error: Missing arg1 (input_path)}
readonly expt_files=${2?Error: Missing arg4 (gene_intervals)}
readonly outfile=${3?Error: Missing arg5 (path prefix for saige output)}

readonly directory="$( dirname ${regex_prefix} )"
readonly filename="$( basename ${regex_prefix} )"

readonly found_files=$( ls ${directory} | grep ${filename} | wc -l)

if [ ${expt_files} = ${found_files} ]; then
  set_up_rpy
  Rscript ${rscript} \
    --in_dir ${directory} \
    --regex ${filename} \
    --n_expt ${expt_files} \
    --out ${outfile}
else
  >&2 echo "Error: Expected ${expt_files} genes but found ${found_files}! Regex used: '${filename}' in directory '${directory}.'"
fi

