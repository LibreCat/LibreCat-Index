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
my $store    = undef;
my $verbose  = undef;
my $test     = undef;
my $clear    = undef;
my $delete   = undef;
my $default_fixes = Catmandu->config->{fixes}->{default};
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
           "delete" => \$delete,
           "v" => \$verbose);

my $source = shift;
my $file = shift;

$file  = '/dev/stdin' if $file eq '-';
$store = $source unless defined $store;

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

    store->commit;

    if ($delete) {  
        importer->each(sub {
            my $obj = $_[0];
            store->delete($obj->{_id});
        });
    }
    else {
        store->add_many(importer);
    }

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

    if (Catmandu->config->{fixes}->{$source}) {
        $default_fixes = Catmandu->config->{fixes}->{$source};
    }

    my @work_fixes = ( @$default_fixes, @$fixes );
    
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
usage: $0 [options] source file

options:
    -v  
    --clear
    --delete
    --test
    --nofix
    --fix=<fix_file>
    --importer=<importer_name>
    --source=<source>
    --store=<store_name>

example: 
    # reindex rug01
    $0 -v --clear rug01 /vol/indexes/incoming/rug01.export

    # test the conversion of aleph sequential to solr indexable data
    $0 --test rug01 /vol/indexes/incoming/rug01.export

    # update rug01 records
    $0 -v rug01 /vol/indexes/incoming/rug01.updates
    
    # delete rug01 records 
    $0 -v --delete rug01 /vol/indexes/incoming/rug01.deletes
EOF
}

sub start {
   return unless $verbose;
   print STDERR "(start $source $store)\n";
}

sub verbose {
   return unless $verbose;
   ++$count;
   my $speed = $count / tv_interval($start);
   printf STDERR " (doc %d %f)\n" , $count, $speed if ($count % 100 == 0);
}

sub stats {
   return unless $verbose;
   my $speed = $count / tv_interval($start);
   printf STDERR " (doc %d %f)\n" , $count, $speed;
   printf STDERR "(end $source)\n";
}
