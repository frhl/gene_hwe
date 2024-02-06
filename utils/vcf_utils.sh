#!/usr/bin/env bash

# Get full path to ukb_utils directory
# NOTE: This assumes this script has not been moved from ukb_utils/bash
# From: https://stackoverflow.com/a/246128
_source="${BASH_SOURCE[0]}"
while [ -h "${_source}" ]; do # resolve $_source until the file is no longer a symlink
  _dir="$( cd -P "$( dirname "${_source}" )" >/dev/null 2>&1 && pwd )"
  _source="$(readlink "${_source}")"
  [[ ${_source} != /* ]] && _source="$_dir/$SOURCE" # if $_source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

#ukb_utils_dir="$( cd -P "$( dirname "$_source" )" >/dev/null 2>&1 && cd ../ && pwd )"
#ukb_utils_dir="/gpfs3/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/wes_ko_ukbb_nexus/utils"

# Required for raise_error and print_update
source "${ukb_utils_dir}/utils/qsub_utils.sh"

bcftools_check() {
  #
  # Checks if bcftools command is available. If not, it points to my installation of bcftools v1.11
  #
  command -v bcftools \
    || raise_error "bcftools not found" 
}

get_eof_error() {
  #
  # Returns >0 number if VCF $1 is truncated
  #
  bcftools view -h $1 2>&1 | head | grep "No BGZF EOF marker" | wc -l
}

vcf_check() {
  #
  # Checks if VCF is valid.
  # Input: Path to VCF
  # 
  bcftools_check
  if [ ! -f $1 ]; then # check that VCF exists
    raise_error "$1 does not exist"
  elif [ ! -s $1 ]; then # check that VCF is not an empty file
    raise_error "$1 exists but is empty"
  elif [ $( get_eof_error $1 ) -gt 0 ]; then # check that VCF is not truncated
    raise_error "$1 may be truncated"
  fi
}


get_slots_vcf() {
  local _cluster=$( get_current_cluster_vcf )
  if [ "${_cluster}" == "sge" ]; then
    echo "${NSLOTS}"
  elif [ "${_cluster}" == "slurm" ]; then
    echo "${SLURM_CPUS_ON_NODE}"
  else
    raise_error "${_cluster} is not a valid cluster!"
  fi
}


get_threads_vcf() {
  local _threads=1
  local _slots=$(get_slots_vcf)
  local _new_threads=$((${_slots}-1))
  if [ "${_new_threads}" -gt "${_threads}" ]; then
    local _threads=${_new_threads}
  fi
  echo "${_threads}"
}


make_tabix() {
  #
  # Makes tabix file for VCF
  # Input: Path to VCF to tabix
  #
  local _cluster="$(get_current_cluster_vcf)"
  local _threads="$(get_threads_vcf)"
  local _index=${2:-"tbi"}
  if [ ! -f "${1}.${_index}" ]; then
    bcftools_check
    local _start_time=${SECONDS}
    bcftools index ${1} \
      --${_index} \
      --threads ${_threads}
    local _duration=$(( ${SECONDS}-${_start_time} ))
    print_update "Finished tabix of $1" "${_duration}"
  fi
}

count_vcf() {
  local vcf_to_count=$1
  local default_reference=${2:-"GRCh38"}
  local indels_only=${3:-0}
  if [ "${SGE_TASK_ID}" != "undefined" ]; then
    local t_flag="-t ${SGE_TASK_ID}"
  else
    local t_flag=""
  fi
  /mgmt/uge/8.6.8/bin/lx-amd64/qsub \
    ${t_flag} \
    -wd ${SGE_O_WORKDIR} \
    -o ${SGE_STDOUT_PATH} \
    -e ${SGE_STDERR_PATH} \
    ${ukb_utils_dir}/bash/count_vcf.sh \
    ${vcf_to_count} \
    ${default_reference} \
    ${indels_only}
}

switch_errors_by_site() {
  # aggregate switch errors by site
  module purge
  module load BCFtools/1.12-GCC-10.3.0
  >&2 echo "Note: (switch_errors_by_site): Purging modules."
  export BCFTOOLS_PLUGINS="/well/lindgren/flassen/software/bcf/bcftools-1.12/plugins"
  local _vcf=${1}
  local _ped=${2}
  local _rscript="utils/aggr_ser.R"
  local _ser="${_vcf%.*.*}.ser"
  local _var="${_vcf%.*.*}.var"
  local _out="${_vcf%.*.*}.txt"
  >&2 echo "Step 1 (switch_errors_by_site): Running +trio-switch_rate for ${_vcf} using ${_ped}."
  bcftools +trio-switch-rate "${_vcf}" -- -p "${_ped}" -c 0 > "${_ser}"
  bcftools query -f '%ID %CHROM %POS %REF %ALT\n' "${_vcf}"  -o "${_var}"
  module purge
  module load R
  >&2 echo "Step 2 (switch_errors_by_site): Finalizing and outputting to ${_out}."
  Rscript ${_rscript} \
    --switch-error-file ${_ser} \
    --variant-file ${_var} \
    --outfile ${_out}
}


# get current cluster
get_current_cluster_vcf() {
  if [ ! -z "${SGE_ACCOUNT:-}" ]; then
    echo "sge"
  elif [ ! -z "${SLURM_JOB_ID:-}" ]; then
    echo "slurm"
  else
    raise_error "Could not find SGE/SLURM variables!"
  fi
}

vcf_check_sample_order() {
  local _vcf1=${1?Error: Missing arg1 (vcf1)}
  local _vcf2=${2?Error: Missing arg2 (vcf2)}
  local _tmp1=$(mktemp)
  local _tmp2=$(mktemp)
  bcftools query -l ${_vcf1} > ${_tmp1}
  bcftools query -l ${_vcf2} > ${_tmp2}
  local _wc1=$( cat ${_tmp1} | wc -l )
  local _wc2=$( cat ${_tmp2} | wc -l )
  local diff=$( cmp ${_tmp1} ${_tmp2} )
  if [ "${_wc1}" != "${_wc2}" ]; then
    echo >&2 "WARNING: Different sample counts in the two VCFs!"
  fi
  if [ "${#diff}" -gt 0 ]; then
    echo >&2 "WARNING: Different sample orders in the two VCFs!"
  fi

}



vcf_concat_sort () {
  local _vcf1=${1?Error: Missing arg1 (vcf1)}
  local _vcf2=${2?Error: Missing arg2 (vcf2)}
  local _out=${3?Error: Missing arg3 (outfile.vcf.gz)}
  local _tmp_dir=${4?Error: Missing arg1 (temp dir)}
  local _bname1=$(basename -- "${_vcf1}")
  local _dname1=$(dirname "${_vcf1}")
  local _tmp="${_dname1}/${_bname1%%.*}_srt_var.vcf.gz"

  echo "tmp loc: ${_tmp}" 
  # NOTE: This function relies on locally installed bcftools
  # ensure that the bcftools_local variable is set to the right path

  if [ ! -f ${_out} ]; then
    # 3. combine the two vcf files on top of each other (thus requiring a sort opereation)
    if [ ! -f "${_tmp}" ]; then
      >&2 echo "Step 1: Concatenating VCFs.."
      ${bcftools_local} concat ${_vcf1} ${_vcf2} -oZ -o ${_tmp}
    else
      >&2 echo "Concatenated VCF (${_tmp}) already exists. Skipping."
    fi
  
    # 4. sort the file to avoid error:
    # [E::hts_idx_push] Unsorted positions on sequence #1: 46664399 followed by 10414352
    # index: failed to create index for "did_this_work.vcf.gz"
    if [ ! -f "${out_file}" ]; then
      >&2 echo "Step 2: Sorting ${_tmp}.."
      ${bcftools_local} sort ${_tmp} --temp-dir ${_tmp_dir} -oZ -o ${_out}
    else
      >&2 echo "${_out} already exists. Skipping"
    fi
    # clean up files
    if [ -f "${_out}" ]; then
      >&2 echo "Cleaning up temporary files.."
      rm "${_tmp}"
      echo "Sucess. Writing to ${_out}"
    fi
  else
    >&2 echo "${_out} already exists! "
  fi

}


