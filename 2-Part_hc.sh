#!/bin/bash

dir=$1
fold='.'
wd="$(pwd)/$dir";
script_fold="$fold/gatk4/";
source_f=$2;
node='nodeX';
list='inputSamples.txt';
tempGvcf='tempGvcf';

echo "Working dir: $wd";


if [[ -d $1 && -f $2 ]]; then
	
	cd $wd
		
	#Call HC
	echo "sbatch -p low --nodelist=$node --job-name HC2 -e $wd/logs/HC_2part.e -o $wd/logs/HC_2part.o --export=temp=$tempGvcf,source_f=$source_f,list=$list $script_fold/2-Part_hc.sbatch" > 2_Part.sh

        #Call The first part of the variant calling
	bash 2_Part.sh

else
        echo "
        SYNTAX:

        - $( basename $0 ) <folder> <source_file>
        ";
fi
