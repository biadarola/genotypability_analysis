#!/bin/bash

dir=$1;
wd="$(pwd)/$dir";
fold='.'
script_fold="$fold/gatk4/";
source_f=$2;
vcf='variants.recalibrated.vcf';
node='nodeX';

echo "Working dir: $wd";


if [[ -d $1 && -f $2 ]]; then
	
	cd $wd
	
	#Call HC
	echo "sbatch -p low --nodelist=$node --job-name VarFilt -e $wd/logs/Var_filtering.e -o $wd/logs/Var_Filtering.o --export=vcf=$vcf,source_f=$source_f,dir='results' $script_fold/3-HardFilter.sbatch" > HD_filtering.sh

        #Call The first part of the variant calling
	bash HD_filtering.sh

else
        echo "
        SYNTAX:

        - $( basename $0 ) <vcf> <source_file> 
        ";
fi

