#!/usr/bin/env bash

source utils/bash_utils.sh
source utils/qsub_utils.sh

echo "$(pwd)"

readonly rscript=${1?Error: Missing arg1 (in_vcf)}
readonly sample_size=${2?Error: Missing arg2 (in_vcf)}
readonly current_k=${3?Error: Missing arg2 (in_vcf)}
readonly alternative=${4?Error: Missing arg2 (in_vcf)}
readonly sig_level=${5?Error: Missing arg2 (in_vcf)}
readonly out_prefix=${6?Error: Missing arg8 (in_vcf)}

set_up_rpy
Rscript ${rscript} \
  --current_k ${current_k} \
  --sample_size ${sample_size} \
  --alternative ${alternative} \
  --sig_level ${sig_level} \
  --out_prefix ${out_prefix}

