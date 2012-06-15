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
my $default_fixes = [q{copy_field("_id","fSYS")},q{meercat()},q{marc_xml("fXML")},q{remove_field('record')}];
my $nofix    = undef;
my $fixes    = [];
my $count    = 0;
my $start    = [gettimeofday];

GetOptions("store=s" => \$store, 
           "importer=s" => \$importer, 
           "fix=s@" => \$fixes,
           "nofix" => \$nofix,
           "test" => \$test,
           "clear" => \$clear,
           "source=s" => \$source,
           "v" => \$verbose);

my $file = shift;

unless (defined $store && defined $file && -r $file) {
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

    my @work_fixes = ( @$default_fixes, @$fixes);
    
    if ($source) {
        unshift(@work_fixes
            , "add_field('source','$source')"
            , "copy_field('_id','$source')"
        );
    }
   
    if (!defined $nofix && @work_fixes > 0) {
        my $fixer = Catmandu::Fix->new(fixes=>\@work_fixes);
        $it = $fixer->fix($it);
    }
    
    $it
}

sub usage {
    print STDERR <<EOF;
usage: $0 [options] infile

options:
    -v  
    --clear
    --test
    --nofix
    --fix=<fix_file>
    --importer=<importer_name>
    --source=<source>
    --store=<store_name>
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
