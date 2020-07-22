#!/usr/bin/perl

# by ciano

use strict;
use warnings;
use Cwd 'abs_path';

my $bam = '';
my @RX  = ();
foreach my $f (@ARGV)
{
    if ( -f $f && $f =~ m/bam$/i )
    {
        $bam = abs_path($f);
    }
    elsif ( $f eq '--fgbioUMI' )
    {
        @RX = ( '--BARCODE_TAG', 'RX' );
    }
}

my @dir = split /\//, $bam;
pop @dir;

my $DEST    = join '/', @dir, 'alignment.rg.bam';
my $METRICS = join '/', @dir, 'duplicates.txt';
my $TEMP = "./temp";

if ( -f $bam && !-f $DEST && !-f $METRICS )
{

    my @cmd = (
	'java','-Xmx20G',"-Djava.io.tmpdir=$TEMP", '-jar',
        './script/picard.jar',                  'MarkDuplicates',
        "I=$bam",
        "O=$DEST",
        "M=$METRICS",
        "REMOVE_DUPLICATES=true",
        "VALIDATION_STRINGENCY=SILENT",
        "CREATE_INDEX=true"
    );

    push @cmd, @RX if ( defined $RX[1] && $RX[1] eq 'RX' );

    my $datestring = localtime();
    print STDERR qq|STOP MarkDuplicates at $datestring with command:\n|;
    print STDERR join( ' ', @cmd ), "\n";

    system(@cmd);

    $datestring = localtime();
    print STDERR qq|END MarkDuplicates at $datestring\n|;
}
else
{
    my $nn = $0;
    $nn =~ s/^.*\///;
    print STDERR qq|
SYNTAX:

 - $0 <file.bam> [--fgbioUMI]

|;
}
