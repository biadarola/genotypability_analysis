#!/usr/bin/perl

# by ciano

use strict;
use warnings;

my $norm = 2000000;    # * 67850;

my $SAMTOOLS = 'samtools';

my $coverage = '';
my $normReg  = '';
my @files    = ();

#
# parse parameters
#
foreach my $p (@ARGV)
{
    if ( -f $p )
    {
        push @files, $p;
    }
    elsif ( $p eq 'coverage' )
    {
        $coverage = $p;
    }
    elsif ( $p =~ m/^\d+$/ )
    {
        $norm = $p;
    }
    elsif ( $p eq '--normReg' )
    {
        $normReg = '--normReg';
    }
}

if ( !defined $files[0] )
{
    print STDERR qq|
SYNTAX:

 - $0 <region_coverage1> <region_coverage2> ... <region_coverageN> [norm_val] [--normReg]

 - $0 coverage <file.bam> <file.bed>

NOTE:
 - norm_val is total number of reads to normalize in bam
 - --normReg normalize the average coverage of all regions to 1000

|;
    exit;
}

if (   $coverage eq 'coverage'
    && $files[0] =~ m/\.bam$/
    && $files[1] =~ m/\.bed$/ )
{
    &regionCoverage(@files);
    exit;
}

my %ss = ();

my %reg = ();

foreach my $file (@files)
{
    my $total = 0;
    open( FILE, $file ) || die;
    while (<FILE>)
    {
        chomp;
        my @a = split /\t/;

        my $key = join "\t", $a[0], $a[1], $a[2], $a[3];
        $reg{ $a[0] }->{ $a[1] }->{ $a[2] } = $a[3];

        $ss{$key}->{$file} = $a[4];
        $total += $a[4];
    }
    close FILE;

    # print $file, "\t", $total, "\n";
    my $ratio = $norm / $total;

    $total = 0;

    foreach my $chr ( sort keys %reg )
    {
        foreach my $start ( sort { $a <=> $b } keys %{ $reg{$chr} } )
        {
            foreach
              my $stop ( sort { $a <=> $b } keys %{ $reg{$chr}->{$start} } )
            {
                my @ccc =
                  ( $chr, $start, $stop, $reg{$chr}->{$start}->{$stop} );
                my $reg = join "\t", @ccc;
                $ss{$reg}->{$file} = $ss{$reg}->{$file} * $ratio;
            }
        }
    }
}

#
# print header
#
print "chrom\tstart\tstop\tgene";

foreach (@ARGV)
{
    my @a = split '/';
    print "\t" . $a[-2] if ( -f $_ );
}
print qq|\tmin\tmax\tdiff\tstdev\n|;

foreach my $chr ( sort keys %reg )
{
    foreach my $start ( sort { $a <=> $b } keys %{ $reg{$chr} } )
    {
        foreach my $stop ( sort { $a <=> $b } keys %{ $reg{$chr}->{$start} } )
        {
            my @ccc = ( $chr, $start, $stop, $reg{$chr}->{$start}->{$stop} );
            my $reg = join "\t", @ccc;
            my @row = ();
            foreach my $file (@ARGV)
            {
                push @row, int( $ss{$reg}->{$file} + 0.5 ) if ( -f $file );
            }
            my @test = sort { $a <=> $b } @row;
            my $stdev = &stdev( \@row );
            if ( $normReg eq '--normReg' )
            {
                my $average = &average( \@row );
                foreach (@row)
                {
                    $_ = 1000 / $average * $_;
                }
            }

            # next if ( $stdev * 10 < $test[0] );
            print join( "\t",
                @ccc, @row, $test[0], $test[-1], $test[-1] - $test[0], $stdev ),
              "\n";
        }
    }
}

sub average
{
    my $data = shift;
    if ( not @$data )
    {
        die("Empty arrayn");
    }
    my $total = 0;
    foreach (@$data)
    {
        $total += $_;
    }
    my $average = $total / @$data;
    return $average;
}

sub stdev
{
    my $data = shift;
    if ( @$data == 1 )
    {
        return 0;
    }
    my $average = &average($data);
    my $sqtotal = 0;
    foreach (@$data)
    {
        $sqtotal += ( $average - $_ )**2;
    }
    my $std = ( $sqtotal / ( @$data - 1 ) )**0.5;
    return $std;
}

sub regionCoverage
{
    my $bam = shift;
    my $bed = shift;

    my @a = split '/', $bam;
    $a[-1] = $bed;
    $a[-1] =~ s/^.*\///;
    $a[-1] =~ s/.bed/-coverage.region.bed/;
    my $dest = join '/', @a;
    return if ( -f $dest );

    #open( FILE, "$SAMTOOLS bedcov $bed $bam |" )
    open( FILE, "$SAMTOOLS bedcov -Q 1 $bed $bam |" )
      || die "Couldn't execute samtools on file $ARGV[0]\n\n";
    open( OUT, ">$dest" ) || die;

    while (<FILE>)
    {
        chomp;
        @a = split /\t/;
        print OUT join( "\t", @a, $a[2] - $a[1] ), "\n";
    }
    close FILE;
    close OUT;
}
