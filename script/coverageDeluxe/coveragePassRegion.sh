#!/bin/bash

# by ciano

#HH=$( dirname $( realpath $0 ) ) ;
BEDTOOLS="./script/bedtools" ;

if [[ -f $1 && -f $2 ]]; then
$BEDTOOLS coverage -hist -a $1 -b $2 ;
exit;
fi

echo "
SYNTAX:

 - $( basename $0 ) <callable.bed> <design.bed>

";
