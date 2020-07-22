#!/bin/bash

# by ciano

#give the configuration file
source $2

GATK="./script/gatk-4.1.4.0/gatk";

#check bam file is given as input
if [[ ! -f $1 ]]; then
echo "SYNTAX:";
echo;
echo " - `basename $0` <dedup.bam>";
echo;
exit;
fi

INTERVAL='';
if [[ -f $3 ]]; then
INTERVAL="--interval-padding 150 -L $2";
fi

DEST=$( dirname $( realpath $1 ) )/$( basename $1 .bam ).recal_data.table ;

if [[ -f $1 && ! -f $DEST ]] ; then

echo "Start BaseRecalibrator on $1 at `date`";

$GATK BaseRecalibrator -R $FASTA -I $1 --use-original-qualities -O $DEST --known-sites $MILLS --known-sites $DBSNP --tmp-dir ./temp;

echo "Ended BaseRecalibrator on $1 at `date`";

fi

DESTBAM=$( dirname $( realpath $1 ) )/$( basename $1 .bam ).recalibrated.bam ;

if [[ -f $1 && -f $DEST && ! -f $DESTBAM ]] ; then

echo "Start ApplyBQSR on $1 at `date`";

$GATK ApplyBQSR -R $FASTA -I $1 -O $DESTBAM -bqsr $DEST \
	--static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30 \
	--add-output-sam-program-record --create-output-bam-md5 --use-original-qualities $INTERVAL --tmp-dir ./temp;

echo "Ended ApplyBQSR on $1 at `date`";

fi
