#!/bin/bash

# by ciano

DIR=$( dirname $( realpath $1 ) ) ;
DEST=$(basename $1 .bam);
PICARD="./script/picard.jar";

cd $DIR || exit;

if [[ ! -f $DEST.hist.pdf || ! -f $DEST.output ]]; then
	java -jar $PICARD CollectInsertSizeMetrics I=$(basename $1) H=$DEST.hist.pdf O=$DEST.output AS=true VALIDATION_STRINGENCY=SILENT ;
fi
