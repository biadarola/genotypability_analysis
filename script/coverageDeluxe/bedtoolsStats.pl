#!/usr/bin/perl

#
# Script exit if the output files were already created
#

use strict;
use warnings;

my $len   = 0;
my $bases = 0;

my $b1  = 0;
my $b5  = 0;
my $b10 = 0;
my $b20 = 0;
my $b30 = 0;

while (<STDIN>)
{
    chomp;
    if ( m/^all/ || m/^genome/ )
    {
        my @a = split /\t/;
        $len = $a[3];
        $bases += ( $a[1] * $a[2] );

        if ( $a[1] >= 30 )
        {
            $b1  += $a[2];
            $b5  += $a[2];
            $b10 += $a[2];
            $b20 += $a[2];
            $b30 += $a[2];
        }
        elsif ( $a[1] >= 20 )
        {
            $b1  += $a[2];
            $b5  += $a[2];
            $b10 += $a[2];
            $b20 += $a[2];
        }
        elsif ( $a[1] >= 10 )
        {
            $b1  += $a[2];
            $b5  += $a[2];
            $b10 += $a[2];
        }
        elsif ( $a[1] >= 5 )
        {
            $b1 += $a[2];
            $b5 += $a[2];
        }
        elsif ( $a[1] >= 1 )
        {
            $b1 += $a[2];
        }
    }
}

my $avg = sprintf( "%0.2f", $bases / $len );
print join( "\t", $len, $bases, $b1, $b5, $b10, $b20, $b30, $avg ), "\n";
