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
use Data::UUID;
use Getopt::Long;
use Time::HiRes qw(gettimeofday tv_interval);
use LWP::UserAgent;
use LWP::Simple;
use File::Temp qw(tempfile);
use HTTP::Request::Common;
use subs qw(store importer exporter binary_import);

Catmandu->load;

my $importer = 'default';
my $store    = undef;
my $verbose  = undef;
my $test     = undef;
my $binary   = undef;
my $clear    = undef;
my $delete   = undef;
my $default_fixes = Catmandu->config->{fixes}->{default};
my $nofix    = undef;
my $fixes    = [];
my $count    = 0;
my $start    = [gettimeofday];
my $tmpdir   = '/tmp';

GetOptions("store=s" => \$store, 
           "importer=s" => \$importer, 
           "fix=s@" => \$fixes,
           "nofix" => \$nofix,
           "test" => \$test,
           "binary" => \$binary,
           "clear" => \$clear,
           "delete" => \$delete,
           "tmpdir=s" => \$tmpdir,
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
elsif ($binary) {
    store->delete_all if $clear;

    store->commit;

    if ($delete) {  
        importer->each(sub {
            my $obj = $_[0];
            store->delete($obj->{_id});
        });
    }
    else {
        importer->each(sub {
            my $obj = $_[0];
            binary_import($obj); 
        });
    }

    store->commit;
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

sub binary_import {
    my $obj = $_[0];

    return undef unless $obj->{content};

    # Declare a local variable for temporary files (files get deleted when the vars go out of scope)
    my ($fh,$filename);

    # Fetch a local copy of the remote file
    if ($obj->{content} =~ /^http(s)?:/) {
        ($fh,$filename) = tempfile();

        my $rc = getstore($obj->{content},$filename);

        unless (is_success($rc)) {
            warn "$rc - $obj->{content} mirror $filename";
            warn status_message($rc);
            return undef;
        }

        $obj->{content} = $filename;
    }

    return undef unless -r $obj->{content};

    my $ua  = LWP::UserAgent->new;
    my $url = Catmandu->store($store)->url . "/update/extract" ;

    my $bag    = 'data';
    my $bag_id = Data::UUID->new->create_str;

    my $response;
  
    eval { 
        $response = $ua->request( 
             POST $url ,
             Content_Type => 'form-data',
             Content      => _obj_to_literal($obj)
             );
    };
    if ($@) {
        warn $@;
        return undef;
    }

    unless ($response->is_success) {
        warn $response->status_line;
        return undef;
    }

    return 1;
}

sub _obj_to_literal {
    my $obj = $_[0];

    my $literal = [];

    delete $obj->{title};

    for my $name (keys %$obj) {
        my $value = $obj->{$name};

        if ($name eq 'content') {
            push(@$literal,"fulltxt" => [$value]);
        }
        elsif (ref($value) eq 'ARRAY') {
            for (@$value) {
                push(@$literal,"literal.$name" => $_);
            }
        }
        else {
            push(@$literal,"literal.$name" => $value);
        }
    }

    push(@$literal,"literal._bag" => 'data');

    return $literal;
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
    --binary [experimental]
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
