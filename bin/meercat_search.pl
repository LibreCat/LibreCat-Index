#!/usr/bin/env perl
#
# Query Meercat indexes
#
# Patrick Hochstenbach Jun 2012
#
use Catmandu;
use Data::Dumper;
use Getopt::Long;

Catmandu->load;

my $num   = undef;
my $store = 'default';

GetOptions("store=s" => \$store, "num" => \$num);

my $query = shift;

unless (defined $query) {
   &usage;
   exit(1);
}

if ($num) {
 my $hits  = Catmandu->store($store)->bag->search(query => $query);
 printf "%s hits\n",  $hits->total; 
}
else {
 my $hits  = Catmandu->store($store)->bag->searcher(query => $query);
 $hits->each(sub {
  my $obj = $_[0];
  for my $key (keys %$obj) {
     my $val = $obj->{$key};
     if (ref($val) eq 'ARRAY') {
        for (@$val) {
           print "$key: $_\n";
        }
     }
     else {
        print "$key: $val\n";
     }
  }
  print "\n";
 });
}

sub usage {
   print STDERR <<EOF;
usage: $0 [options] query

options:

   --num
   --store=<store_name>
EOF
}
