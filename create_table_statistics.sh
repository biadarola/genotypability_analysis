#!/bin/bash

#Enter in the directory
cd $1

echo "Current directory $(pwd)";

script="./script/coverageDeluxe/metricsParser.pl";

#Creates all tables
##fragments %GC content
echo "Fragment %GC content";

for i in $(cat inputSamples.txt); do perl $script $i//fastqc/*R2*.html ; done > GCcontent.xlsx

#insert size
echo "Insert size design";
for i in $(cat inputSamples.txt); do perl $script $i//alignment.rg.*.output; done > insert_des_size_clip.xlsx

#mapdeduplicates
echo "Map deduplicate";
for i in $(cat inputSamples.txt); do perl $script $i//flagstat_recal ; done > map_dedup_clip.xlsx

#duplicates 
echo "Duplicates";
for i in $(cat inputSamples.txt); do perl $script $i//duplicates.txt ; done > duplicates_clip.xlsx

#Reference Statistics
echo "Reference statistics";
for i in $(cat inputSamples.txt); do echo -n -e "$i\t" ; cat $i//refseq_hg38_*DP10-stats.tsv | head -1 | awk '{for (i=3; i<NF; i++) printf $i " "; print $NF}'; done > refStatistics_clip.xlsx

#ON/OFF/NEAR Target Ref
echo "Reference ON/OFF/NEAR Target";
for i in $(cat inputSamples.txt); do perl $script $i//refseq*HsMetrics.txt ; done > ref_HsMetrics_clip.xlsx

#Design Statistics
echo "Design statistics";
for i in $(cat inputSamples.txt); do echo -n -e "$i\t" ; cat $i//[!refseq_]*-callable_DP10-stats.tsv | head -1 | awk '{for (i=3; i<NF; i++) printf $i " "; print $NF}'; done > designStatistics_clip.xlsx

#ON/OFF/NEAR Target Des
echo "Design ON/OFF/NEAR Target";
for i in $(cat inputSamples.txt); do perl $script $i//alignment.rg.*[!refseq_]*.HsMetrics.txt ; done > des_HsMetrics_clip.xlsx

echo "Create xlxs total";
paste -d" " GCcontent.xlsx insert_des_size_clip.xlsx map_dedup_clip.xlsx duplicates_clip.xlsx refStatistics_clip.xlsx designStatistics_clip.xlsx des_HsMetrics_clip.xlsx > statistics_clip.csv

rm *.xlsx

