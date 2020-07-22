#!/bin/bash

disco_dir=$1
node='nodeX'
wd="$(pwd)/$disco_dir";
script_fold=".";
source_f=$2;
kit=$3;
echo "Working dir: $wd";

if [[ -d $1 && -f $2 ]]; then

	#create a list of input of the directory
	cd $wd
	echo "Sono qui $(pwd)";

	if [[ ! -f inputSamples.txt ]]; then
		ls > inputSamples.txt;
		sed -i '/inputSamples.txt/d' ./inputSamples.txt;
	fi


	if [[ ! -d $wd/logs ]] ; then
		mkdir -p $wd/logs/fastqc;
		 mkdir -p $wd/logs/alignment;
	fi

	#Call fastq
	sbatch -p low --job-name fastqc_$1 --nodelist=$node --error $wd/logs/fastqc/fastqc_$1.e --output $wd/logs/fastqc/fastqc_$1.o  --export=dir=$wd ./fastqc.sbatch
	bash toDo_fastqc.sh

	#Crea file bash 
	sbatch -p low --job-name $1 --nodelist=$node --error $wd/logs/alignment/align_$1.e --output $wd/logs/alignment/align_$1.o --export=dir=$wd,source_file=$source_f,kit=$kit $script_fold/align_stat_pipe.sbatch

	#Call The first part of the variant calling
        bash toDo_align_stat.sh

else
        echo "
        SYNTAX:

        - $( basename $0 ) <folder> <source_file> <kit>

        ";
fi
