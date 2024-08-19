#!/usr/bin/sh
#SBATCH -A ACD113027        # Account name/project number
#SBATCH -J vep        # Job name
#SBATCH -p ngs53G
#SBATCH -c 8               # 使用的core數 請參考Queue資源設定 
#SBATCH --mem=53g           # 使用的記憶體量 請參考Queue資源設定
#SBATCH --mail-user=
#SBATCH --mail-type=FAIL

# Path of VEP
VEP_PATH=/opt/ohpc/Taiwania3/pkg/biology/Ensembl-VEP/ensembl-vep/vep
VEP_CACHE_DIR=/opt/ohpc/Taiwania3/pkg/biology/DATABASE/VEP/Cache
VEP_FASTA=/opt/ohpc/Taiwania3/pkg/biology/reference/Homo_sapiens/GATK/hg38/Homo_sapiens_assembly38.fasta
BCFTOOLS=/opt/ohpc/Taiwania3/pkg/biology/BCFtools/bcftools_v1.13/bin/bcftools

INPUT_VCF=/staging/biology/r12455009/JIA_WES/vep/JIA_all_assoc_bfile_convert.vcf
OUTPUT_VCF_PATH=/staging/biology/r12455009/JIA_WES/vep
SAMPLE_ID=JIA25_pick.VEP

cd $OUTPUT_VCF_PATH

module load old-module
module load biology/Perl/5.28.1
export PATH=${PATH}:/opt/ohpc/Taiwania3/pkg/biology/HTSLIB/htslib_v1.13/bin:/opt/ohpc/Taiwania3/pkg/biology/SAMTOOLS/samtools_v1.15.1/bin
set -euo pipefail

# Log file settings
TIME=`date +%Y%m%d%H%M`
logfile=./${TIME}_run_vep.log

# Redirect standard output and error to the log file
exec > "$logfile" 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') Job started" >> ${logfile}

$VEP_PATH --cache --offline \
	-i $INPUT_VCF \
	--format vcf \
	--fork 4 \
	--check_existing \
	--force_overwrite \
	--dir_cache $VEP_CACHE_DIR \
	--assembly GRCh38 \
	--merged \
	--fasta $VEP_FASTA \
	--vcf \
	-o ${SAMPLE_ID}.vcf

# generate tsv
echo -e "CHROM\tPOS\tREF\tALT\t$(${BCFTOOLS} +split-vep -l ${SAMPLE_ID}.vcf | cut -f 2 | tr '\n' '\t' | sed 's/\t$//')" > ${SAMPLE_ID}.tsv
${BCFTOOLS} +split-vep -f '%CHROM\t%POS\t%REF\t%ALT\t%CSQ\n' -d -A tab ${SAMPLE_ID}.vcf >> ${SAMPLE_ID}.tsv

echo "$(date '+%Y-%m-%d %H:%M:%S') Job finished" >> ${logfile}
