#!/bin/bash
#SBATCH --mem=50000
#SBATCH -c 10


# URLs:
# https://gatkforums.broadinstitute.org/gatk/discussion/2806/howto-apply-hard-filters-to-a-call-set
# https://software.broadinstitute.org/gatk/documentation/article.php?id=3225
# https://software.broadinstitute.org/gatk/documentation/article.php?id=11069

source ${source_f}

gatk="./script/gatk-4.1.4.0/gatk";
dir=${dir};
vcf=${vcf};

#enter in the folder with the vcf
cd $dir;

if [[ -f $vcf ]]; then

# extract SNPs from unfiltered variants
if [[ ! -f raw_snps.vcf ]] ; then
	$gatk SelectVariants --select-type-to-include SNP --output raw_snps.vcf -V $vcf ;
fi

# extract all the others from unfiltered variants
if [[ ! -f raw_indels.vcf ]] ; then
	$gatk SelectVariants --select-type-to-exclude SNP --output raw_indels.vcf -V $vcf ;
fi

# filter SNPs
if [[ ! -f raw_filtered_snps.vcf ]]; then
	$gatk VariantFiltration -R $FASTA -V raw_snps.vcf \
		--filter-expression "QD < 2.0 || MQ < 40.0 || FS > 60.0 || SOR > 3.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" \
		--filter-name "Broad_SNP_filter" -O  raw_filtered_snps.vcf ;
fi

# filter indels
if [[ ! -f raw_filtered_indels.vcf ]]; then
	$gatk VariantFiltration -R $FASTA -V raw_indels.vcf \
		--filter-expression "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0" \
		--filter-name "Broad_indel_Filter" -O raw_filtered_indels.vcf ;
fi

# merge filtered variants
if [[ ! -f variants.filtered.vcf.gz ]]; then
	$gatk MergeVcfs -I raw_filtered_snps.vcf -I raw_filtered_indels.vcf -O variants.filtered.vcf ;
	bgzip variants.filtered.vcf ;
	tabix variants.filtered.vcf.gz ;
fi

# select PASS variants
if [[ ! -f variants.selected.vcf.gz ]] ; then
	$gatk SelectVariants -R $FASTA --variant variants.filtered.vcf.gz --exclude-filtered -O variants.selected.vcf ;
	bgzip variants.selected.vcf ;
	tabix variants.selected.vcf.gz ;
fi

# clean intermediate files
if [[ -f variants.selected.vcf.gz ]] ; then
	rm raw_snps.vcf raw_filtered_snps.vcf raw_filtered_indels.vcf raw_indels.vcf *.idx ;
fi

# remove old files
if [[ -f chr* ]] ; then
	rm chr*
fi

fi
