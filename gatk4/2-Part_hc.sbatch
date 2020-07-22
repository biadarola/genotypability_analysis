#!/bin/bash
#SBATCH -c 15
#SBATCH --mem-per-cpu=10000

###USAGE ./script tempGvcf list_of_samples source file 
#### the list of samples takes as input a file in which each line is represented by a sample
source ${source_f}

tempGvcf=${temp}
listofSamples=${list}
temp='./temp';

#############creation of the directori1es#############################
mkdir results ;

############################### paths ##################################################
gatk='./script/gatk-4.1.4.0/gatk';

###################################################################################################
######## here I create an array in which I store the id of the sample, this array will be used in the following command line 
######## where the genomicdB is created for each of the intervals sotred in the intevals file #################
                                                                                                                  
myarra=();                                                                                                          
                                                                                                                  
for i in $(cat $listofSamples); do myarra+=("-V $tempGvcf/$i.snps.raw.g.vcf"  )  ; done      
                                                            
echo "sharded genomics DB creation started at `date`";                                                            
printf '%s\n' "${myarra[@]}";                                                                                    

$gatk CombineGVCFs -O $tempGvcf/complete.g.vcf -R $FASTA ${myarra[@]} --tmp-dir $temp -L $Genome_intervals 

echo "sharded genomics DB creation finished at `date`";

echo "...starting variant calling at `date`";

$gatk  GenotypeGVCFs -R $FASTA -V $tempGvcf/complete.g.vcf -G StandardAnnotation -O results/complete.raw.vcf --tmp-dir $temp -L $Genome_intervals

echo "variant calling finished at `date`";


echo "Start indexing at `date`";

$gatk IndexFeatureFile -I results/complete.raw.vcf

echo "Finished indexing at `date`";

# URL references:
# https://github.com/gatk-workflows/gatk4-germline-snps-indels/blob/5e3d54aa68899248af066b2fbf00954ae052f9b7/joint-discovery-gatk4-local.hg38.wgs.inputs.json
# https://github.com/gatk-workflows/gatk4-germline-snps-indels/blob/3087accf86b325bb5b511f2e7f6e8574fc0c1ff0/joint-discovery-gatk4.wdl

cd results

if [[ -f complete.raw.vcf ]]; then

	# create indel_tranche
	indel_tranche=" ";
	for aa in "100.0" "99.95" "99.9" "99.5" "99.0" "97.0" "96.0" "95.0" "94.0" "93.5" "93.0" "92.0" "91.0" "90.0" ; do
	indel_tranche="$indel_tranche -tranche $aa ";
	done

	# create snps_tranche
	snps_tranche=" ";
	for aa in "100.0" "99.95" "99.9" "99.8" "99.6" "99.5" "99.4" "99.3" "99.0" "98.0" "97.0" "90.0" ; do
	snps_tranche="$snps_tranche -tranche $aa" ;
	done


	#
	# CREATE INDELS MODEL
	#

	if [[ ! -f INDEL.tranches || ! -f INDEL.recalibration.idx ]] ; then
	echo "Start VariantRecalibrator indels at `date`";
	$gatk VariantRecalibrator --tmp-dir=$temp -V complete.raw.vcf -O INDEL.recalibration -L $Genome_intervals --tranches-file INDEL.tranches --trust-all-polymorphic \
		$indel_tranche \
		--use-annotation "FS" --use-annotation "ReadPosRankSum" --use-annotation "MQRankSum" --use-annotation "QD" --use-annotation "SOR" --use-annotation "DP" \
		-mode INDEL --max-gaussians 4 -R $FASTA \
		--resource:mills,known=false,training=true,truth=true,prior=12.0 $MILLS \
		--resource:axiomPoly,known=false,training=true,truth=false,prior=10.0 $AXIOM \
		--resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $DBSNP ;
	fi


	#
	# CREATE SNP MODEL
	#
	if [[ ! -f SNPS.recalibration.idx || ! -f SNPS.tranches ]] ; then
	echo "Start VariantRecalibrator SNPs at `date`";
	$gatk VariantRecalibrator --tmp-dir=$temp -V complete.raw.vcf -O SNPS.recalibration -L $Genome_intervals --tranches-file SNPS.tranches --trust-all-polymorphic \
		$snps_tranche -mode SNP --max-gaussians 6 \
		--use-annotation "QD" --use-annotation "MQRankSum" --use-annotation "ReadPosRankSum" --use-annotation "FS" --use-annotation "MQ" --use-annotation "SOR" --use-annotation "DP" \
		--resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP \
		--resource:omni,known=false,training=true,truth=true,prior=12.0 $OMNI \
		--resource:1000G,known=false,training=true,truth=false,prior=10.0 $PHASE1 \
		--resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $DBSNP ;
	fi

	#
	# APPLY INDELS MODEL
	#
	if [[ ! -f  indel.recalibrated.vcf.idx ]] ; then
	echo "Start ApplyVQSR indels at `date`";
	$gatk ApplyVQSR --tmp-dir=$temp -O indel.recalibrated.vcf -V complete.raw.vcf -L $Genome_intervals --recal-file INDEL.recalibration --tranches-file INDEL.tranches \
		--truth-sensitivity-filter-level 99.7 --create-output-variant-index true -mode INDEL ;
	fi

	#
	# APPLY SNPS MODEL
	#
	if [[ ! -f variants.recalibrated.vcf.idx ]] ; then
	echo "Start ApplyVQSR SNPs at `date`";
	$gatk ApplyVQSR --tmp-dir=$temp -O variants.recalibrated.vcf -V indel.recalibrated.vcf -L $Genome_intervals --recal-file SNPS.recalibration --tranches-file SNPS.tranches \
		--truth-sensitivity-filter-level 99.7 --create-output-variant-index true -mode SNP ;
	fi

	echo "All done at `date`";

fi

# URLs:
# https://gatkforums.broadinstitute.org/gatk/discussion/2806/howto-apply-hard-filters-to-a-call-set
# https://software.broadinstitute.org/gatk/documentation/article.php?id=3225
# https://software.broadinstitute.org/gatk/documentation/article.php?id=11069

if [[ -f variants.recalibrated.vcf ]]; then

	# extract SNPs from unfiltered variants
	if [[ ! -f raw_snps.vcf ]] ; then
		$gatk SelectVariants --select-type-to-include SNP --output raw_snps.vcf -V variants.recalibrated.vcf ;
	fi

	# extract all the others from unfiltered variants
	if [[ ! -f raw_indels.vcf ]] ; then
		$gatk SelectVariants --select-type-to-exclude SNP --output raw_indels.vcf -V variants.recalibrated.vcf ;
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
		rm chr* INDEL.* SNPS.* indel.* 
	fi

fi
