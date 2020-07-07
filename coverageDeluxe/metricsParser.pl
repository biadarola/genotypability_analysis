#!/usr/bin/perl

# by ciano

use strict;
use warnings;

if ( defined $ARGV[0] && -f $ARGV[0] )
{
    if ( $ARGV[0] =~ m/html$/ )
    {
        &getFastqc( $ARGV[0] );
    }
    elsif ( $ARGV[0] =~ m/dupl.*.txt/ || $ARGV[0] =~ m/dedup.*txt/ )
    {
        &getDuplicates( $ARGV[0] );
    }
    elsif ( $ARGV[0] =~ m/flagstat/ )
    {
        &getFlagstats( $ARGV[0] );
    }
    elsif ( $ARGV[0] =~ m/output$/ )
    {
        &insertSize( $ARGV[0] );
    }
    elsif ( $ARGV[0] =~ m/HsMetrics\.txt$/ )
    {
        &getHsMetrics( $ARGV[0] );
    }
    elsif ( $ARGV[0] =~ m/stats\.tsv$/ )
    {
        &getCoverage( $ARGV[0] );
    }
    else { &help(); }
}
else { &help(); }

sub help
{
    print STDERR qq|
SYNTAX:

 - $0 <filename>

The program retrieves metrict from file that match:

 - html == fastqc (numeber of frags and %GC)
 - *.output == CollectInsertSizeMetrics (average insert size)
 - dupl*.txt == MarkDuplicated (% duplicates)
 - flagstat == samtools flagstats (# mapped fragments)
 - *stats.tsv == first line of gene stats table
 - HsMetrics.txt == picard HsMetrics
   (ON_BAIT_BASES, NEAR_BAIT_BASES, OFF_BAIT_BASES,
    FOLD_ENRICHMENT, FOLD_80_BASE_PENALTY)
|;
}

sub getFastqc
{
    my $html = shift;

    open( FILE, qq{lynx --dump $html | } ) || die;
    my $sample = '.';
    my @a = split '/', $html;
    $sample = $a[0] if ( $#a > 0 );

    my $reads = 0;
    my $len   = 0;
    my $gc    = 0;
    while (<FILE>)
    {
        chomp;
        $reads = $1 if (m/Total\s+Sequences\s+(\d+)\s*$/);
        $len   = $1 if (m/Sequence\s+length\s+(\d.*)\s*$/);
        $gc    = $1 if (m/%GC\s+(\d+)\s*$/);
    }
    close FILE;
    print join( "\t", $sample, $reads, $gc, $len ), "\n";
}

sub getCoverage
{
    my $file = shift;

    open( FILE, $file ) || die;
    my $sample = '.';
    my @a = split '/', $file;
    $sample = $a[-2] if ( $#a > 0 );

    my $line = <FILE>;
    close FILE;
    chomp $line;

    @a = split /\t/, $line;
    return if ( $a[0] ne 'all' );
    shift @a;
    $a[0] = $sample;
    print join( "\t", @a ), "\n";
}

sub getFlagstats
{
    my $file = shift;

    # le reads con mate mapped valgono un frammento.
    # i singletons valgono un frammento
    my $supplementary = 0;
    my $mate_mapped   = 0;
    my $singletons    = 0;

    open( FILE, $file ) || die;
    my $sample = '.';
    my @a = split '/', $file;
    $sample = $a[-2] if ( $#a > 0 );

    while (<FILE>)
    {
        chomp;

        # $supplementary = $1 if (m/^(\d+)\s.+supplementary$/);

        $mate_mapped = int( $1 / 2 )
          if (m/^(\d+)\s.+with\s+itself\s+and\s+mate\s+mapped$/);

        $singletons = $1 if (m/^(\d+)\s.+singletons.+\)$/);
    }
    close FILE;
    print join( "\t", $sample, $supplementary + $mate_mapped + $singletons ),
      "\n";
}

sub getDuplicates
{
    my $dup = shift;
    open( FILE, $dup ) || die;
    my $sample = '.';
    my @a = split '/', $dup;
    $sample = $a[-2] if ( $#a > 0 );

    while (<FILE>)
    {
        chomp;
        @a = split /\t/;
        if ( $#a > 8 && $a[8] =~ m/^0\.\d+/ )
        {
            print join( "\t", $sample, sprintf( "%.2f", $a[8] * 100 ) ), "\n";
            last;
        }
    }
    close FILE;
}

sub insertSize
{
    my $size = shift;
    open( FILE, $size ) || die;
    my $sample = '.';
    my @a = split '/', $size;
    $sample = $a[-2] if ( $#a > 0 );
    my $index = 0;
    while (<FILE>)
    {
        chomp;
        next if (m/^\s*$/);
        @a = split /\t/;
        if ( $a[0] eq 'MEDIAN_INSERT_SIZE' )
        {
            for ( my $i = 0 ; $i < $#a ; $i++ )
            {
                if ( $a[$i] eq 'MEAN_INSERT_SIZE' )
                {
                    $index = $i;
                    last;
                }
            }
            my $dim = <FILE>;
            chomp $dim;
            @a = split /\t/, $dim;
            print join( "\t", $sample, sprintf( "%.2f", $a[$index] ) ), "\n";
            last;
        }
    }
    close FILE;
}

#
# Retrieve the colums:
# - ON_BAIT_BASES
# - NEAR_BAIT_BASES
# - OFF_BAIT_BASES
# - FOLD_ENRICHMENT
# - FOLD_80_BASE_PENALTY
#
sub getHsMetrics
{
    my $file = shift;

    open( FILE, $file ) || die;
    my $sample = '.';
    my @a = split '/', $file;
    $sample = $a[-2] if ( $#a > 0 );

    while (<FILE>)
    {
        chomp;
        if (m/ON_BAIT_BASES\s+NEAR_BAIT_BASES\s+OFF_BAIT_BASES/)
        {
            my %pos = ();
            @a = split /\t/;
            for ( my $i = 0 ; $i <= $#a ; $i++ )
            {
                $pos{ $a[$i] } = $i;
            }
            my $ll = <FILE>;
            chomp $ll;
            @a = split /\t/, $ll;
            print join( "\t",
                $sample,
                $a[ $pos{'ON_BAIT_BASES'} ],
                $a[ $pos{'NEAR_BAIT_BASES'} ],
                $a[ $pos{'OFF_BAIT_BASES'} ],
                sprintf( "%.2f", $a[ $pos{'FOLD_ENRICHMENT'} ] ),
                sprintf( "%.2f", $a[ $pos{'FOLD_80_BASE_PENALTY'} ] ) ),
              "\n";
            last;
        }
    }
    close FILE;
}
