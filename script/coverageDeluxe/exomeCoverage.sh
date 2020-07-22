#!/bin/bash

echo "SYNTAX:" ;
echo " - `basename $0` <file.bam> <target.bed> <callable.bed> [callable_DP10.bed]";

HH=$( dirname $( realpath $0 ) ) ;

BEDTOOLS="./script/bedtools" ;

BASENAME="$(dirname $1)/$( basename $2 .bed ).$( basename $1 .bam )";

if [[ -f $BEDTOOLS && -f $1 && -f $2 && -f $3  ]] ; then

echo "Start region coverage analysis at `date`"

# region coverage
if [[ ! -f $BASENAME-capture.hist.coverage.gz ]] ; then
	$BEDTOOLS coverage -hist -abam $1 -b $2 | gzip > $BASENAME-capture.hist.coverage.gz ;
fi

# prepare region coverage for the callable file
if [[ ! -f $BASENAME-callable.bed ]] ; then
	$HH/coveragePassRegion.sh $3 $2 > $BASENAME-callable.bed ;
fi

# prepare region coverage for the second callable file
if [[ -f $4 && ! -f $BASENAME-$( basename $4 ) ]] ; then
	$HH/coveragePassRegion.sh $4 $2 > $BASENAME-$( basename $4 ) ;
fi

# there are two callable file
if [[ -f $BASENAME-$( basename $4 ) ]] ; then
	$HH/geneCoverage.pl $BASENAME-capture.hist.coverage.gz $BASENAME-callable.bed $BASENAME-$( basename $4 ) ;
fi

# there is only the normal callable file
if [[ ! -f $4 ]]; then
	$HH/geneCoverage.pl $BASENAME-capture.hist.coverage.gz $BASENAME-callable.bed ;
fi

echo "End region coverage analysis at `date`";

fi
