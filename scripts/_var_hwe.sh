#!/usr/bin/env bash

source utils/bash_utils.sh
source utils/qsub_utils.sh

echo "$(pwd)"

readonly rscript=${1?Error: Missing arg1 (in_vcf)}
readonly input_path=${2?Error: Missing arg2 (in_vcf)}
readonly chunk_size=${3?Error: Missing arg5 (in_vcf)}
readonly num_chunks=${4?Error: Missing arg6 (in_vcf)}
readonly out_prefix=${5?Error: Missing arg8 (in_vcf)}
readonly chunk_idx=$( get_array_task_id )

readonly start_line=$(( (chunk_idx - 1) * chunk_size + 1 ))
readonly end_line=$(( chunk_idx * chunk_size ))

echo "chunk idx${chunk_idx}:${start_line}-${end_line}"

readonly out_prefix_chunk="${out_prefix}.${chunk_idx}of${num_chunks}"
readonly outfile="${out_prefix_chunk}.txt.gz"

if [ ! -f "${outfile}" ]; then
  set_up_rpy
  Rscript ${rscript} \
    --input_path ${input_path} \
    --idx_start ${start_line} \
    --idx_end ${end_line} \
    --out_prefix ${out_prefix_chunk}
else
  >&2 echo "${outfile} already exists. Skipping!"
fi

