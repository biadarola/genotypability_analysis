#!/bin/bash

dir=$1
fold='.'
wd="$(pwd)/$dir";
script_fold="$fold/gatk4/";
source_f=$2;
bam='alignment.rg.recalibrated.bam';
node='nodeX'

echo "Working dir: $wd";


if [[ -d $1 && -f $2 ]]; then
	
	cd $wd


        echo "Sono qui $(pwd)";

        if [[ ! -f inputSamples.txt ]]; then
                ls > inputSamples.txt;
                sed -i '/inputSamples.txt/d' ./inputSamples.txt;
        fi


        if [[ ! -d logs ]] ; then
                mkdir -p logs;
        fi
		
	#Call HC
	for i in $(cat inputSamples.txt ); do echo "sbatch -p low --nodelist=$node --job-name HC_$i -e $wd/logs/hc_$i.e -o $wd/logs/hc_$i.o --export=dir=$wd/$i,tempGvcf=tempGvcf,bam=$bam,id=$i,source_f=$source_f $script_fold/1-Caller.sbatch" ; done > HC.sh

        #Call The first part of the variant calling
	bash HC.sh       

else
        echo "
        SYNTAX:

        - $( basename $0 ) <folder> <source_file>
        ";
fi

