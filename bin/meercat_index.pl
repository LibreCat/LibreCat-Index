#!/usr/bin/env perl
#
# Create Meercat indexes
#
# Patrick Hochstenbach Jun 2012
#
use Catmandu;
use Catmandu::Fix;
use Catmandu::Sane;
use Data::Dumper;
use Getopt::Long;
use Time::HiRes qw(gettimeofday tv_interval);
use subs qw(store importer exporter);

Catmandu->load;

my $importer = 'default';
my $source   = undef;
my $store    = undef;
my $verbose  = undef;
my $test     = undef;
my $clear    = undef;
my $fixes    = [qw{copy_field("_id","fSYS") meercat() marc_xml("fXML") remove_field('record')}];
my $count    = 0;
my $start    = [gettimeofday];

GetOptions("store=s" => \$store, 
           "importer=s" => \$importer, 
           "fix=s@" => \$fixes,
           "test" => \$test,
           "clear" => \$clear,
           "source=s" => \$source,
           "v" => \$verbose);

my $file = shift;

unless (defined $store && -r $file) {
    &usage;
    exit(1);
}

&start;

if ($test) {
    exporter->add_many(importer);
}
else {
    store->delete_all if $clear;
    store->add_many(importer);
    store->commit;
}

&stats;

sub store {
    Catmandu->store($store)->bag;
}

sub exporter {
    Catmandu->exporter('default');
}

sub importer {
    my $it = Catmandu->importer($importer,file=>$file)->tap(\&verbose);

    if ($source) {
        unshift(@$fixes
            , "add_field('source','$source')"
            , "copy_field('_id','$source')"
        );
    }
    
    if (@$fixes > 0) {
        my $fixer = Catmandu::Fix->new(fixes=>$fixes);
        $it = $fixer->fix($it);
    }
    
    $it
}

sub usage {
    print STDERR <<EOF;
usage: $0 [options] --store=<store_name> infile

options:
    -v  
    --test
    --fix=<fix_file>
    --importer=<importer_name>
    --source=<source>
EOF
}

sub start {
   return unless $verbose;
   print STDERR "[start]\n";
}

sub verbose {
   return unless $verbose;
   ++$count;
   my $speed = $count / tv_interval($start);
   printf STDERR "doc(%d) : %f docs/sec\n" , $count, $speed if ($count % 100 == 0);
}

sub stats {
   return unless $verbose;
   my $speed = $count / tv_interval($start);
   printf STDERR "doc(%d) : %f docs/sec\n" , $count, $speed;
   printf STDERR "[done]\n";
}
