#!/usr/bin/perl

# by ciano

use strict;
use warnings;
use Cwd 'abs_path';
use Sys::Hostname;

my $BWA = 'bwa';
my $SAMTOOLS = 'samtools';
my $SAMBAMBA = 'sambamba';

if ( -f 'start_sorted.bam' )
{
    print "\nstart_sorted.bam was already created!\n\n";
    exit;
}

my $f1  = '';
my $f2  = '';
my $ref = '';
my $cpu = 0;

foreach my $file (@ARGV)
{
    if ( -f $file )
    {
        if ( $file =~ m/\.fastq/ )
        {
            if ( $f1 eq '' )
            {
                $f1 = abs_path($file);
            }
            elsif ( $f2 eq '' )
            {
                $f2 = abs_path($file);
            }
            else
            {
                print STDERR qq|ERROR: More than 2 fastq files in input!!!\n\n|;
                exit;
            }
        }
        elsif ( $file =~ m/\.fa/ )
        {
            $ref = abs_path($file);
        }
    }
    elsif ( $file =~ m/^\d+$/ )
    {
        $cpu = $file;
    }
}

if ( $f1 ne '' && $ref ne '' && $cpu > 0 )
{
    my $NAME = '';
    my $ID   = '';
    if ( -f 'idinfo.txt' )
    {
        open( FILE, 'idinfo.txt' ) || die;
        $NAME = <FILE>;
        $ID   = <FILE>;
        close FILE;
        chomp $NAME;
        chomp $ID;
    }

    if ( $NAME eq '' || $ID eq '' )
    {
        my @tt = split /\//, $f1;
        $NAME = $tt[-2];
        $ID   = time;
    }

    my $hostname = hostname;
    print STDERR "BWA started on $hostname at " . scalar( localtime() ) . "\n";
    print STDERR qq|
FASTQ1: $f1
FASTQ2: $f2
   REF: $ref
  NAME: $NAME
    ID: $ID
   CPU: $cpu
|;
	
	#per versione bwa-0.7.15
    my $RG = '"@RG'
      . qq|\tID:$ID\tPU:lane\tLB:$NAME\tSM:$NAME\tCN:CGF-ddlab\tPL:ILLUMINA"|;

	print "RG $RG";
	
    my $scpu = 1;
    $scpu = int( $cpu / 5 ) if ( $cpu > 9 );
    my $bcpu = $cpu - $scpu;

`$BWA mem -R $RG -t $bcpu $ref $f1 $f2 | $SAMTOOLS sort --threads $scpu -m 5G - -o start_sorted.bam`;

    # index with sambamba
    print "Indexing...\n";
    system( $SAMBAMBA, 'index', '--nthreads=' . $cpu, 'start_sorted.bam' );

    print "BWA finished on $hostname at " . scalar( localtime() ) . "\n";
}
else
{
    my $nn = $0;
    $nn =~ s/^.*\///;
    print STDERR qq|
SYNTAX:
 - $nn <ref.fasta> <file1.fastq[.gz]> [file2.fastq[.gz]] <#CPU>\n
|;
}
