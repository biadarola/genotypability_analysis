#!/usr/bin/perl

# by ciano

use strict;
use warnings;

print STDERR qq|
SYNTAX:

 - $0 <file1.tsv> ... [fileN.tsv]

|;

my @tsv   = ();
my $lista = '';
foreach my $f (@ARGV)
{
    if ( -f $f )
    {
        if ( $f =~ m/tsv$/i )
        {
            push @tsv, $f;
        }
        else
        {
            $lista = $f;
        }
    }
}

#
# IMPORT AND COUNT GENE NAMES
#
my %geni      = ();
my $countGene = 0;
open( FILE, $lista ) || die;
while (<FILE>)
{
    s/^\s+//;
    s/\s+$//;
    foreach my $g ( split /\s+/ )
    {
        $geni{$g} = 1;
        $countGene++;
    }
}
close FILE;

print STDERR qq|Counted $countGene genes in file $lista\n|;

#
# LOAD ALL THE TSV FILES
#

# chr->gene->file->value(len cov 1 5 10 20 30 pass)->val
my %res   = ();
my $order = ();
foreach my $f (@tsv)
{
    $countGene = 0;
    print STDERR qq|Loading file $f...\n|;
    open( FILE, $f ) || die;
    while (<FILE>)
    {
        chomp;
        my @a = split /\t/;
        if ( defined $geni{ $a[1] } && !defined $res{$f}->{ $a[1] } )
        {
            $countGene++;
            $res{$f}->{ $a[1] }->{'len'}  = $a[2];
            $res{$f}->{ $a[1] }->{'cov'}  = $a[3];
            $res{$f}->{ $a[1] }->{1}      = $a[4];
            $res{$f}->{ $a[1] }->{5}      = $a[5];
            $res{$f}->{ $a[1] }->{10}     = $a[6];
            $res{$f}->{ $a[1] }->{20}     = $a[7];
            $res{$f}->{ $a[1] }->{30}     = $a[8];
            $res{$f}->{ $a[1] }->{'pass'} = $a[9];
        }
    }
    print STDERR qq|Counted $countGene genes in file $f\n|;
    close FILE;

    #
    # CHECK FOR MISSED GENES
    #
    my @missed = ();
    foreach my $gene ( sort keys %geni )
    {
        push @missed, $gene if ( !defined $res{$f}->{$gene} );
    }
    if ( defined $missed[0] )
    {
        print STDERR qq|\nMISSED GENES:\n|;
        print STDERR join( ", ", @missed ), "\n";
        exit;
    }
}

#
# PREPARE STATS FOR GLOBAL GENES SET
#
foreach my $out ( 'cov', 1, 5, 10, 20, 30, 'pass' )
{
    foreach my $f (@tsv)
    {
        foreach my $gene ( keys %geni )
        {
            my $len = $res{$f}->{$gene}->{'len'};
            $res{$f}->{'all'}->{'len'} += $len if ( $out eq 'cov' );
            $res{$f}->{'all'}->{$out} +=
              ( $len * $res{$f}->{$gene}->{$out} / 100 );
        }
    }
}
foreach my $f (@tsv)
{
    foreach my $out ( 'cov', 1, 5, 10, 20, 30, 'pass' )
    {
        $res{$f}->{'all'}->{$out} =
          $res{$f}->{'all'}->{$out} / $res{$f}->{'all'}->{'len'} * 100;
    }
}

#
# PRINT RESULTS TO DISTINCT FILES
#
my $header = join( "\t", 'gene', 'length', @tsv ) . "\n";

foreach my $out ( 1, 5, 10, 20, 30, 'pass' )
{
    open( FILE, ">tabella_$out.tsv" ) || die;
    print FILE $header;

    foreach my $gene ( 'all', sort keys %geni )
    {
        my @row = ($gene);
        my $len = '';
        foreach my $file (@tsv)
        {
            if ( $len eq '' )
            {
                $len = $res{$file}->{$gene}->{'len'};
                push @row, $len;
            }
            push @row, $res{$file}->{$gene}->{$out};
        }
        print FILE join( "\t", @row ), "\n";
    }
    close FILE;
}
