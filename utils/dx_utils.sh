


geq() {
 local target="${1}"
 local geq_than="${2:-1}"
 echo $([[ ${target} -ge ${geq_than} ]] && echo 1 || echo 0)
}

dx_size_in_bytes() {
  local dx_target="${1}"
  if [ $(dx_file_exists ${dx_target}) -eq 1 ]; then
    local file_size=$( dx ls -l ${dx_target} | cut -d' ' -f5-6 | tr -d ' ' | sed 's/ //g')
    local size=$(echo "${file_size}" | sed 's/[A-Za-z]//g')
    local unit=$(echo "${file_size}" | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')
    local size_in_bytes=0
    case "$unit" in
        GB) size_in_bytes=$(awk "BEGIN {print int($size * 1024 * 1024 * 1024)}") ;;
        MB) size_in_bytes=$(awk "BEGIN {print int($size * 1024 * 1024)}") ;;
        KB) size_in_bytes=$(awk "BEGIN {print int($size * 1024)}") ;;
        B)  size_in_bytes=$size ;;
        *)  echo "Unknown size unit: $unit" >&2; return 1 ;;
    esac
    echo ${size_in_bytes}
  else
    echo "0"
    >&2 echo "Warning: '${dx_target}' does not exist."
  fi
}

dx_is_empty() {
  local dx_target="${1}"
  local file_size=$(dx_size_in_bytes "${dx_target}")
  if [[ "${file_size}" -le 25 ]]; then
    echo 1
  else
    echo 0
  fi
}


dx_file_exists() {
 local dx_target="${1}"
 local files_found="$((dx ls --obj ${dx_target}) 2> /dev/null | wc -l)"
 echo "$(geq ${files_found} 1)"
}

dx_dir_exists() {
 local dx_target="${1}"
 local files_found="$((dx ls --folders ${dx_target}) 2> /dev/null | wc -l)"
 echo "$(geq ${files_found} 1)"
}

stopifnot () {
 local target="${1}"
 if [[ ${target} -eq 0 ]]; then
   >&2 echo "stopifnot: error" 
   exit 1
 fi
}


dx_same_as_local() {
 local dx_target="${1}"
 local local_target="${2}"
 # >&2 echo "Checking ${local_target} (local) and ${dx_target} (dnanexus).."
 if [ -f ${local_target} ]; then
    local local_md5=$(cat ${local_target} | md5sum | cut -d" " -f1 )
 else
    >&2 echo "${local_target} does not exists (local)."
    exit 1
 fi
 if [ $(dx_file_exists ${dx_target}) -eq 1 ]; then 
    local dx_md5=$(dx cat ${dx_target} | md5sum | cut -d" " -f1 )
 else
    >&2 echo "${dx_target} does not exists (dnanexus)"
    exit 1
 fi
 echo $([[ ${local_md5} == ${dx_md5} ]] && echo 1 || echo 0)
}

dx_update_remote () {
 local dx_target="${1}"
 local local_target="${2}"
 if [[ $(dx_file_exists ${dx_target}) -eq 0 ]]; then
   dx upload ${local_target} --brief --path ${dx_target}
 else 
   local same_checksum="$(dx_same_as_local ${dx_target} ${local_target})"
   if [[ ${same_checksum} == 0 ]]; then
    >&2 echo "'Local ${local_target}' is different from remote '${dx_target}'. Updating remote '$(basename ${dx_target})'.."
    local dx_newname="${dx_target}.old"
    dx mv ${dx_target} ${dx_newname}
    dx rm ${dx_newname}
    dx upload ${local_target} --brief --path ${dx_target}
   fi
 fi

}


# remove mnt project from string
wo_mnt_project() {
  local input_string="$1"
  echo "${input_string//\/mnt\/project/}"
}








