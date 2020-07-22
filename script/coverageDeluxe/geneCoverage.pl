#!/usr/bin/perl

# by ciano

use strict;
use warnings;

my $HELP = qq|SYNTAX:

 - $0 <coverageBed.bed.gz> <callable1.bed> ... [callable_n.bed]

NOTE:
The destination file will be named: callable_n-stats.tsv

|;

if ( !defined $ARGV[1] )
{
    print STDERR $HELP;

    exit;
}

my $dest = $ARGV[-1];
$dest =~ s/.bed/-stats.tsv/;

if ( -f $dest && -s $dest > 0 )
{
    print STDERR "Nothing to do\n";
    exit;
}
else
{
    print STDERR "Producing stats file: $dest\n";
}

my %ss = ();

my $depth    = '';
my @callable = ();

# number of zero count (7 is covrage depth without callable)
my $init = 7;

foreach my $f (@ARGV)
{
    if ( -f $f )
    {
        if ( $depth eq '' ) { $depth = $f; }
        else
        {
            push @callable, $f;
            $init++;
        }
    }
}

#
# REGION COVERAGE
#
open( FILE, "gzip -dc $depth |" ) || die $HELP;
while (<FILE>)
{
    next if ( m/^all/ || m/^genome/ );

    chomp;

    my @a = split /\t/;

    # single region
    &addRegion(
        $a[0], $a[3], 10000000000 + $a[1],
        $a[5], $a[4], [ 1, 5, 10, 20, 30 ],
        2, 1
    );

    # genes
    &addRegion( $a[0], $a[3], $a[3], $a[5], $a[4], [ 1, 5, 10, 20, 30 ], 2, 1 );

    # full bed
    &addRegion( 'all', 'all', 'all', $a[5], $a[4], [ 1, 5, 10, 20, 30 ], 2, 1 );
}
close FILE;

#
# PASS REGION
#
my $countCall = 0;
foreach my $cc (@callable)
{
    open( FILE, $cc ) || die $HELP;
    while (<FILE>)
    {
        next if ( m/^all/ || m/^genome/ );

        chomp;
        my @a = split /\t/;
        next if ( $a[-4] != 1 );

        # single region
        &addRegion( $a[0], $a[3], 10000000000 + $a[1],
            $a[5], $a[4], [1], 7 + $countCall, 0 );

        # genes
        &addRegion( $a[0], $a[3], $a[3], $a[5], $a[4], [1], 7 + $countCall, 0 );

        # full bed
        &addRegion( 'all', 'all', 'all', $a[5], $a[4], [1], 7 + $countCall, 0 );
    }
    close FILE;
    $countCall++;
}

#
# PRINT RESULTS
#
open( OUT, ">$dest" ) || die;
print OUT join( "\t", @{ &printRegion( 'all', 'all', 'all' ) } ), "\n";

foreach my $chr ( sort keys %ss )
{
    foreach my $gene ( sort keys %{ $ss{$chr} } )
    {
        next if ( $gene eq 'all' );
        print OUT join( "\t", @{ &printRegion( $chr, $gene, $gene ) } ), "\n";
    }
}

foreach my $chr ( sort keys %ss )
{
    foreach my $gene ( sort keys %{ $ss{$chr} } )
    {
        foreach my $pos ( sort keys %{ $ss{$chr}->{$gene} } )
        {
            next if ( $pos eq $gene );
            print OUT join( "\t", @{ &printRegion( $chr, $gene, $pos ) } ),
              "\n";
        }
    }
}
close OUT;

#
# PRINT A REGION
#
# INPUT:
# - region name
# - null or "all" to print cumulative
#
sub printRegion
{
    my $chr    = shift;
    my $region = shift;
    my $coord  = shift;

    my $key = $region;
    if ( $region ne $coord )
    {
        $key .= qq|::$coord|;
        $key =~ s/::10+/::/;
    }

    my @row = ( $chr, $key, $ss{$chr}->{$region}->{$coord}->[0] );

    # mean coverage
    push @row,
      sprintf( "%0.2f",
        $ss{$chr}->{$region}->{$coord}->[1] /
          $ss{$chr}->{$region}->{$coord}->[0] );

    # % cov 1x
    push @row,
      sprintf( "%0.2f",
        100 * $ss{$chr}->{$region}->{$coord}->[2] /
          $ss{$chr}->{$region}->{$coord}->[0] );

    # % cov 5x
    push @row,
      sprintf( "%0.2f",
        100 * $ss{$chr}->{$region}->{$coord}->[3] /
          $ss{$chr}->{$region}->{$coord}->[0] );

    # % cov 10x
    push @row,
      sprintf( "%0.2f",
        100 * $ss{$chr}->{$region}->{$coord}->[4] /
          $ss{$chr}->{$region}->{$coord}->[0] );

    # % cov 20x
    push @row,
      sprintf( "%0.2f",
        100 * $ss{$chr}->{$region}->{$coord}->[5] /
          $ss{$chr}->{$region}->{$coord}->[0] );

    # % cov 30x
    push @row,
      sprintf( "%0.2f",
        100 * $ss{$chr}->{$region}->{$coord}->[6] /
          $ss{$chr}->{$region}->{$coord}->[0] );

    # pass
    for ( my $i = 0 ; $i <= $#callable ; $i++ )
    {
        push @row,
          sprintf( "%0.2f",
            100 * $ss{$chr}->{$region}->{$coord}->[ 7 + $i ] /
              $ss{$chr}->{$region}->{$coord}->[0] );
    }

    return \@row;
}

#
# The function updates the hash with the coverage.
#
# INPUT:
# - gene name (column 4 in bed file)
# - keys (join '|', $a[0], $a[1],$a[2])
# - length
# - number of bases
#
sub addRegion
{
    my $chr          = shift;
    my $name         = shift;
    my $region       = shift;
    my $length       = shift;
    my $coverage     = shift;
    my $soglie       = shift;
    my $index        = shift;
    my $updateLength = shift;

    if ( !defined $ss{$chr}->{$name}->{$region} )
    {
        $ss{$chr}->{$name}->{$region} = [ 0, 0, 0, 0, 0, 0, 0 ];
        for (@callable)
        {
            push @{ $ss{$chr}->{$name}->{$region} }, 0;
        }
    }

    if ( defined $updateLength && $updateLength > 0 )
    {
        # update region length
        $ss{$chr}->{$name}->{$region}->[0] += $length;

        # update number of bases in region
        $ss{$chr}->{$name}->{$region}->[1] += ( $coverage * $length );
    }

    foreach my $soglia (@$soglie)
    {
        if ( $coverage >= $soglia )
        {
            $ss{$chr}->{$name}->{$region}->[$index] += $length;
        }
        $index++;
    }
}
