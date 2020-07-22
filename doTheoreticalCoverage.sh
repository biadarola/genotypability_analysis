#!/bin/bash

#Lanciare da cartella 
#bash script.sh nome_campione #framm

sample=$1;
size=$2;

#create directory
if [[ ! -d ./logs ]]; then
	mkdir -p ./logs;
fi

mkdir $sample/140

#Downsampling of data at given size
srun --nodelist=nodeX --mem-per-cpu=8000 -c 8 --error ./logs/seqtk_$sample.err seqtk sample -s100 $sample/*R1*.fastq.gz $size > $sample/140/R1.fastq &

srun --nodelist=nodeX --mem-per-cpu=8000 -c 8 --error ./logs/seqtk_$sample.err seqtk sample -s100 $sample/*R2*.fastq.gz $size > $sample/140/R2.fastq &

gzip ./$sample/140/R1.fastq ;
gzip ./$sample/140/R2.fastq ;
