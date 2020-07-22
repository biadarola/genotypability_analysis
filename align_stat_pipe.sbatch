#!/bin/bash
#SBATCH -c 15
#SBATCH --mem-per-cpu=8000

#module load samtools/1.9
#module load bedtools/2.27.1
#module load bwa/0.7.17
#module load java/jdk1.8.0_144
#module load sambamba/0.6.7
#module load scythe/0.991
#module load sickle/1.33


#Recall variables
source ${source_file}

source_f=${source_file};
kit=${kit};
##Define variables
sample=${dir};
home='.' ;

#Function definition

trimming(){
	if [[  -e $(ls | grep "R1") &&  -e $(ls | grep "R2") ]]; then
		echo "Current directory $(pwd)!";
                echo "Starting trimming at `date`";
                $home/script/trimFastq.sh $(ls | grep "R1") $(ls | grep "R2");
        else
                echo "R1.fastq.gz && R2.fastq.gz does not exists!";
                exit;
        fi

}

mapping(){
	if [[ -f trimmed1.fastq.gz && -f trimmed2.fastq.gz ]]; then
                echo "Starting mapping at `date`";
                $home/script/mapBWA.pl $FASTA trimmed*fastq.gz 10
        else
                echo "Trimmed fastq does not exists!";
                exit;
        fi

}


bam_cleaning(){
	
	 if [[ -f start_sorted.bam ]]; then
                BAM="start_sorted.bam";
                echo "Starting samtools at `date`";
                samtools flagstat $BAM > flagstat ;
		echo "Starting clipping at `date`";
                $home/script/bamUtil/bam clipOverlap --in alignment.rg.bam --out alignment.rg.clipped.bam;
                echo "Starting mark duplicates at `date`";
                $home/script/doMarkDuplicates.pl $BAM ;
                echo "Starting base recalibrator at `date`";
                $home/script/doBaseRecalibrator.sh alignment.rg.clipped.bam $source_f;

        else
                echo "start_sorted.bam does not exists!";
                exit;
        fi


}


create_statistics(){

	 if [[ -f alignment.rg.clipped.recalibrated.bam ]]; then
                bam="alignment.rg.clipped.recalibrated.bam";
                echo "Starting collect insert metrics at `date`";
                $home/script/collectInsertSizeMetrics.sh $bam ;
                echo "Starting samtools at `date`";
		echo "BAM: $bam";
                samtools flagstat $bam > flagstat_recal ;

                insert=`$home/script/coverageDeluxe/metricsParser.pl $(basename $bam .bam).output | cut -f2`;
                insert=`printf "%.0f\n" $insert`;

                echo "insert: $insert";
                echo "Used insert $insert" >> $sample/README.txt

                echo "Starting collect HsMetrics at `date`";
                $home/script/collectHsMetrics.sh $FASTA $bam $OLD_RefSeq_interval $insert;
                $home/script/collectHsMetrics.sh $FASTA $bam $kit_interval $insert;

                echo "Starting callable loci at `date`";
                $home/script/coverageDeluxe/doCallableLoci.pl $FASTA $bam ;
                $home/script/coverageDeluxe/doCallableLoci.pl $FASTA $bam 10 ;

                $home/script/coverageDeluxe/exomeCoverage.sh $bam $OLD_RefSeq_bed callable.bed callable_DP10.bed ;
                $home/script/coverageDeluxe/exomeCoverage.sh $bam $kit_bed callable.bed callable_DP10.bed ;
        else
                echo "alignment.rg.recalibrated.bam does not exists!";
                exit;
        fi
}

if [[ -d $sample && -f $source_f ]]; then
        cd $sample
        echo "Current directory $(pwd)!";
	if [[ $kit == "IDT" ]]
	then
		kit_bed=$IDT_bed;
		kit_interval=$IDT_intervals;
		echo "kit used: $IDT_bed";
	elif [[ $kit == "Agilent" ]];
	then
		kit_bed=$AG_V6_bed;
		kit_interval=$AG_V6_interval;
                echo "kit used: $AG_V6_bed";
	elif [[ $kit == "Medexome" ]];
	then
		kit_bed=$MED_bed;
		kit_interval=$MED_interval;
                echo "kit used: $MED_bed";
	elif [[ $kit == "Twist" ]];
	then
		kit_bed=$TW_Spike_bed;
		kit_interval=$TW_Spike_inteval;
                echo "kit used: $TW_Spike_bed";
	else
		echo "kit not found";
	fi

        trimming
        mapping
        bam_cleaning
        create_statistics
else
        echo "
        SYNTAX:

        - $( basename $0 ) <sample> <source_file> <kit>

        ";
fi







