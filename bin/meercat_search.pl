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
my $fq    = undef;
my $facet_field = undef;
my $facet = 'false';
my $sort  = undef;

GetOptions("store=s" => \$store, "num" => \$num , "fq=s" => \$fq , "facet_field=s" => \$facet_field, "sort=s" => \$sort);

my $query = shift;

unless (defined $query) {
   &usage;
   exit(1);
}

if ($facet_field) {
    $facet = 'true';
    $num   = 1;
}

if ($num) {
 my $hits  = Catmandu->store($store)->bag->search(query => $query, fq => $fq, "facet.field" => $facet_field, sort => $sort , facet => $facet);
 printf "%s hits\n",  $hits->total; 

 if ($hits->{facets}) {
     &print_facets($hits);
 }
}
else {
 my $hits  = Catmandu->store($store)->bag->searcher(query => $query, fq => $fq, "facet.field" => $facet_field, sort => $sort , facet => $facet);
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

sub print_facets {
   my $hits = $_[0];

   for my $facet (keys %{ $hits->{facets}->{facet_fields} }) {
        print "[$facet]\n";
        my $values = $hits->{facets}->{facet_fields}->{$facet};
        for (my $i = 0 ; $i < @$values ; $i += 2) {
            printf "%s: %s\n" , $values->[$i], $values->[$i+1];
        }
   }
}

sub usage {
   print STDERR <<EOF;
usage: $0 [options] query

options:
   --fq=<facet_query>
   --facet_field=<facet.field>
   --sort=<sort>
   --num
   --store=<store_name>
EOF
}
