#!/usr/bin/perl

# by ciano

use strict;
use warnings;

my $SAMBAMBA = 'sambamba';

if ( defined $ARGV[2] && -f $ARGV[0] && -f $ARGV[1] && $ARGV[2] =~ m/^\d+$/ )
{
    &downsamplingBAM(@ARGV);
}
else
{
    print STDERR qq|
SYNTAX:

   - $0 <file.bam> <file.tsv> <target_coverage>

|;
}

sub downsamplingBAM
{
    my $bam = shift;
    my $tsv = shift;
    my $cov = shift;

    my $d = 'd';
    $d = 'r' if ( $tsv =~ m/^r/i );
    if ( -f qq|$cov/$bam| || -f qq|$cov$d/$bam| )
    {
        print STDERR qq|Downsampled file already produced!\n|;
        return;
    }

    # calculate ratio for downsampling
    # if mean coverage is near or less that the one desired
    # the script create a link to the original bam
    open( TSV, $tsv ) || die "NO tsv file\n";
    my $real = <TSV>;
    close TSV;
    chomp $real;
    my @a = split "\t", $real;
    $real = $a[3];

    my $ratio = sprintf( "%0.3f", $cov / $real );
    print STDERR qq|real: $real
target: $cov
ratio: $ratio
|;

    my $fiveperc = $cov * 0.05;

    if ( $real < $cov - $fiveperc )
    {
        print STDERR qq|NO downsampling: target coverage >> real coverage!\n|;
        return;
    }

    # make destination directory
    mkdir $cov if ( !-d $cov );

    if ( $cov + $fiveperc >= $real && $cov - $fiveperc <= $real )
    {
        chdir($cov);
        system( '/bin/ln', qq|../$bam| );
        $bam =~ s/m$/i/;
        system( '/bin/ln', qq|../$bam| );
    }
    else
    {
        system( $SAMBAMBA, 'view', '-h', '-t', 30, '-s', $ratio, '-f', 'bam',
            $bam, '-o', qq|$cov/$bam| );
    }
}
