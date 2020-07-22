CREATE PANEL DESIGN BED
=======================

**convert_IGV_refseq_to_bed.pl**

EXAMPLE:

    convert_IGV_refseq_to_bed.pl -cds lista_geni.txt refGene.txt | sort -k1,1V -k2,2n -k3,3n | grep -v _ | mergeBed -o distinct -c 4

**doDesignStatistics.sh**

EXAMPLE:

    doDesignStatistics.sh ditta_design.bed target_lab.bed 100 230

OUTPUT:

   * global_summary.txt
   * folder coverage_stats_output


TARGET COVERAGE
===============

**exomeCoverage.sh**

To use the script prepare the callable.bed with the pass regions:

    for aa in */*status.bed ; do grep -w CALLABLE $aa | cut -f 1,2,3  > $(dirname $aa)/callable.bed ; done

Target design **must** have the region name:

    chr19	44905743	44905928	APOE
    chr19	44906015	44906049	APOE
    chr19	44906395	44906529	APOE
    chr19	44906581	44906672	APOE
    chr19	44907754	44907957	APOE
    chr19	44908527	44909400	APOE

Calculate coverage stats:

    exomeCoverage.sh recal.sorted.bam ../ABJ.b38.targets.merged.bed callable.bed

OUTPUT is a file with extension .stats.tsv with all the coverage statisticts.


FOLD ENRICHMENT
===============

**bed2intervals.sh**

the script converts a sorted bed file (with region name) to an intervals file.

**calculateMetrics.sh**

The script calculates the HsMetrics to get the FOLD 80 value and the FOLD enrichment value.

**foldFromHSmetrict.sh**

The script extract the two columns from the *calculateMetrics.sh* output


OTHER SCRIPS
============

**bedtoolsStats.pl**

Create coverage statistics from:

    bedtools coverage -hist -abam file.bam -b target.bed


**bedLength.sh**

self explicative :)


**covXgene.sh**

Used by doDesignStatistics.sh


**doCallablePerc.sh**

    doCallablePerc.sh callable.bed target.bed

Prints out the percentage of callable bp


**doGenesTable.pl**

Compare different **.stats.tsv** tables


**geneCoverage.pl**

Used by exomeCoverage.sh


**genomeCoverage.sh**

    genomeCoverage.sh file.bam

Prints the coverage statstics for a WGS bam file


**normalizza.pl**

Region coverage checker. Can be used to check for possible CNV


**theoreticalCoverage.pl**

    theoreticalCoverage.pl <fastqc_data.txt> <target.bed> <read_length>

Calculate the theoretical coverage for a sample
