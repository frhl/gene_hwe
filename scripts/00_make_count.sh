#!/usr/bin/env bash
#
#SBATCH --account=lindgren.prj
#SBATCH --job-name=export_counts
#SBATCH --chdir=/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/gene_hwe
#SBATCH --output=logs/export_counts.log
#SBATCH --error=logs/export_counts.errors.log
#SBATCH --partition=short
#SBATCH --cpus-per-task 1
#SBATCH --array=1-22

set -o errexit
set -o nounset

source utils/bash_utils.sh
source utils/qsub_utils.sh

readonly task_id=$( get_array_task_id )
readonly chr=$( get_chr ${task_id} )

readonly in_dir="data/gnomad/exomes/download"
readonly out_dir="data/gnomad/counts"

readonly in_vcf="${in_dir}/gnomad.exomes.v4.0.sites.chr${chr}.vcf.bgz"
readonly out_path_with_non_ukb="${out_dir}/gnomad.exomes.v4.0.sites.chr${chr}.counts.non_ukb.txt.gz"
readonly out_path_without_non_ukb="${out_dir}/gnomad.exomes.v4.0.sites.chr${chr}.counts.all.txt.gz"

mkdir -p ${out_dir}

module load BCFtools

# Header and data for the file with "non_ukb" in the field names
# Header and data for the file with "non_ukb" in the field names
echo -e "SNPID AC_non_ukb_nfe AN_non_ukb_nfe nhomalt_non_ukb_nfe AC_non_ukb_afr AN_non_ukb_afr nhomalt_non_ukb_afr AC_non_ukb_eas AN_non_ukb_eas nhomalt_non_ukb_eas AC_non_ukb_amr AN_non_ukb_amr nhomalt_non_ukb_amr AC_non_ukb_fin AN_non_ukb_fin nhomalt_non_ukb_fin AC_non_ukb_sas AN_non_ukb_sas nhomalt_non_ukb_sas AC_non_ukb_asj AN_non_ukb_asj nhomalt_non_ukb_asj" | gzip > ${out_path_with_non_ukb}
bcftools query -f "%CHROM:%POS:%REF:%ALT %INFO/AC_non_ukb_nfe %INFO/AN_non_ukb_nfe %INFO/nhomalt_non_ukb_nfe %INFO/AC_non_ukb_afr %INFO/AN_non_ukb_afr %INFO/nhomalt_non_ukb_afr %INFO/AC_non_ukb_eas %INFO/AN_non_ukb_eas %INFO/nhomalt_non_ukb_eas %INFO/AC_non_ukb_amr %INFO/AN_non_ukb_amr %INFO/nhomalt_non_ukb_amr %INFO/AC_non_ukb_fin %INFO/AN_non_ukb_fin %INFO/nhomalt_non_ukb_fin %INFO/AC_non_ukb_sas %INFO/AN_non_ukb_sas %INFO/nhomalt_non_ukb_sas %INFO/AC_non_ukb_asj %INFO/AN_non_ukb_asj %INFO/nhomalt_non_ukb_asj\n" ${in_vcf} | gzip >> ${out_path_with_non_ukb}

# Header and data for the file without "non_ukb" in the field names
#echo -e "SNPID AC_nfe AN_nfe nhomalt_nfe AC_afr AN_afr nhomalt_afr AC_eas AN_eas nhomalt_eas AC_amr AN_amr nhomalt_amr AC_fin AN_fin nhomalt_fin AC_sas AN_sas nhomalt_sas AC_asj AN_asj nhomalt_asj" | gzip > ${out_path_without_non_ukb}
#bcftools query -f "%CHROM:%POS:%REF:%ALT %INFO/AC_nfe %INFO/AN_nfe %INFO/nhomalt_nfe %INFO/AC_afr %INFO/AN_afr %INFO/nhomalt_afr %INFO/AC_eas %INFO/AN_eas %INFO/nhomalt_eas %INFO/AC_amr %INFO/AN_amr %INFO/nhomalt_amr %INFO/AC_fin %INFO/AN_fin %INFO/nhomalt_fin %INFO/AC_sas %INFO/AN_sas %INFO/nhomalt_sas %INFO/AC_asj %INFO/AN_asj %INFO/nhomalt_asj\n" ${in_vcf} | gzip >> ${out_path_without_non_ukb}




