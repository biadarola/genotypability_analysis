#!/bin/sh
#SBATCH -c 2 
#SBATCH --nodelist=nodeX

#This scripts takes as input the sample folder

module load FastQC/0.11.7

#Enter in the script folder
cd ${dir};

echo "Current directory $(pwd)";
echo "Process start at `date`";

mkdir fastqc;

#Run the script
fastqc *f*q.gz -o fastqc --extract 
#--extract 

echo "Process end at `date`";

