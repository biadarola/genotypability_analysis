#!/usr/bin/perl

# by ciano

use strict;
use warnings;
use Cwd 'abs_path';

my $help = $0;
$help =~ s/^.*\///;
$help = qq|
SYNTAX:

 - $help <ref.fasta> <file.bam> [target.bed] [depth]

|;

my $ref   = '';
my $bam   = '';
my $bed   = '';
my $depth = -1;

foreach my $f (@ARGV)
{
    if ( -f $f )
    {
        if    ( $f =~ m/\.fa/ )   { $ref = abs_path($f); }
        elsif ( $f =~ m/\.bam$/ ) { $bam = abs_path($f); }
        elsif ( $f =~ m/\.bed$/ ) { $bed = abs_path($f); }
    }
    elsif ( $f =~ m/^\d+$/ )
    {
        $depth = $f;
    }
}

# creo directory name
my @bb = split /\//, $bam;
pop @bb;
my $dir = join '/', @bb;

my $out = $bam;
$out =~ s/.bam//i;

print STDERR qq|INPUTs:\n|;
print STDERR qq|- REFERENCE: $ref\n|;
print STDERR qq|- BAM: $bam\n|;
print STDERR qq|- BED: $bed\n|;
print STDERR qq|- DEPTH: $depth (-1 is default)\n|;

if ( $ref ne '' && $bam ne '' )
{

    #
    # prepare command
    #
    my @cmd = ( './script/coverageDeluxe/gatk38', '-T', 'CallableLoci', '-R', $ref, '-I', $bam );

    my $summary     = $out . "_callable_table.txt";
    my $callable    = $out . "_callable_status.bed";
    my $callableBED = '/callable.bed';

    #
    # add regions parameter
    #
    if ( $bed ne '' )
    {
        push @cmd, '-L';
        push @cmd, $bed;
    }

    #
    # add minDepth parameter
    #
    if ( $depth > 0 )
    {
        push @cmd, '-minDepth';
        push @cmd, $depth;
        $summary     = $out . "_callable_table_DP$depth.txt";
        $callable    = $out . "_callable_status_DP$depth.bed";
        $callableBED = "callable_DP$depth.bed";
    }

    #
    # add destination file with correct names
    #
    push @cmd, '-summary';
    push @cmd, $summary;
    push @cmd, '-o';
    push @cmd, $callable;

    #
    # PRINT INPUT LOG
    #
    print STDERR qq|BAM: $bam\nREF: $ref\nBED: $bed\nDP: $depth\n|;
    print STDERR join( ' ', @cmd ), "\n";

    #
    # RUN CallableLoci
    #
    system(@cmd) if ( !-f $callable );

    #
    # if exist the CallableLoci file, then create the callable
    #
    open( FILE, $callable ) || die;
    open( OUT, qq|>$dir/$callableBED| ) || die;
    while (<FILE>)
    {
        chomp;
        @bb = split /\t/;
        if ( $bb[-1] eq 'CALLABLE' )
        {
            print OUT join( "\t", $bb[0], $bb[1], $bb[2] ), "\n";
        }
    }
    close FILE;
    close OUT;
}
else
{
    print STDERR $help;
}
