#!/bin/bash
#SBATCH -c 15
#SBATCH --mem=50000
#SBATCH --error HC.e
#SBATCH --output HC.o

module load parallel/20180222

#Recall variables
source ${source_f}

source_f=${source_f};

#dichiarazione variabili

gatk='./script/gatk-4.1.4.0/gatk';
temp='./temp';

#   Check if the BAM file satisfies the requirements of the GATK
#cd ${dir} #directory data da riga di comando

echo "Job started on `hostname` at `date`" ;
echo "Current directory $(pwd)";

bam=${dir}/${bam}
echo "Bam: $bam";

if [[ ! -d ${tempGvcf} ]]; then
	mkdir -p "${tempGvcf}" ;
fi

if  [[ ! -f *.snps.raw.g.vcf ]]; then

	echo "Start HaplotypeCaller for sample $id at `date`";

	#for each intervall call HaplotypeCaller (parallelized jobs)
	#-L {} = -L indica gli intervalli mentre le parentesi {}=passa il parametro precedente a questa variabile
	#-ERC GVCF =  With GVCF , you get a gVCF with individual variant records for variant sites, but the non-variant sites
	#are grouped together into non-variant block records that represent intervals of sites for which the genotype quality (GQ) is within a certain range or band. 

	$gatk HaplotypeCaller -R $FASTA -I $bam -ERC GVCF --output ${tempGvcf}/${id}.snps.raw.g.vcf --standard-min-confidence-threshold-for-calling 30.0 --dont-use-soft-clipped-bases true --tmp-dir $temp -L $Genome_intervals;

	echo "Ended HaplotypeCaller for sample $id at `date`";

fi
