#!/bin/bash

echo ;
echo "SYNTAX:" ;
echo ;
echo "  - $(basename $0) <ref.fasta> <file.bam> <target.intervals> <insert.length>" ;
echo ;


if [[ -f $1 && -f $2 && -f $3 && -n 4 ]]; then

FASTA=$1;
INTERVALS=$( realpath $3 ) ;
BAM=$( realpath $2 );
insert=$4;
PICARD="./script/picard.jar";
temp="./temp"

DIR=$( dirname $BAM ) ;

cd $DIR || exit;

PREF=$( basename $BAM .bam ).$( basename $INTERVALS .intervals ) ;

if [[ ! -f $PREF.PER_BASE_COVERAGE.txt ]] ; then
java -Xmx80G -Djava.io.tmpdir=$temp -jar $PICARD CollectHsMetrics I=$BAM O=$PREF.HsMetrics.txt R=$FASTA \
	BAIT_INTERVALS=$INTERVALS TARGET_INTERVALS=$INTERVALS \
	PER_TARGET_COVERAGE=$PREF.PER_TARGET_COVERAGE.txt \
	PER_BASE_COVERAGE=$PREF.PER_BASE_COVERAGE.txt \
	VALIDATION_STRINGENCY=SILENT \
	NEAR_DISTANCE=$insert 
fi
fi
