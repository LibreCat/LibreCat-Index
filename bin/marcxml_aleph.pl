#!/usr/bin/env perl

use XML::Parser;
use Getopt::Long;

my $type = 'SE';

GetOptions("type=s" => \$type);

my $file = shift;

die "usage: $0 file" unless $file;

$file = '/dev/stdin' if $file eq '-';

my $parser = XML::Parser->new(Handlers => {
                                Start => \&xml_start,
                                End   => \&xml_end,
                                Char  => \&xml_char,
                              });

binmode(STDOUT,"encoding(UTF-8)");
$parser->parsefile($file);

my $recid = 1;
my $field = undef;
my $subfield = undef;
my $ind1  = undef;
my $ind2  = undef;
my $value = undef;
my $read  = undef;

sub xml_start {
   my ($xp,$element,%attr) = @_;

   if ($element eq 'leader') {
        $field = 'LDR';
        $read  = 1;
        &marc_field(0,'FMT',"","",$type);
        $recid++;
   }
   elsif ($element eq 'controlfield') {
        $field = $attr{tag};
        $read  = 1;
   }
   elsif ($element eq 'datafield') {
        $field = $attr{tag};
        $ind1  = $attr{ind1};
        $ind2  = $attr{ind2};
        $read  = undef;
   }
   elsif ($element eq 'subfield') {
        $subfield = $attr{code};
        $read  = 1;
        $value .= '$$' . $subfield;
   }
   else {
        $field = undef;
        $read  = undef;
   }
}

sub xml_char {
   my ($xp,$string) = @_;

   if ($read) {
       $value .= $string;
   }
}

sub xml_end {
   my ($xp, $element) = @_;
   $read  = undef;
   return unless $element =~ /^leader|controlfield|datafield/;
   &marc_field(0, $field, $ind1, $ind2, $value);
   $field = undef;
   $subfield = undef;
   $ind1  = undef;
   $ind2  = undef;
   $value = undef;
}

sub marc_field {
   my ($id,$field,$ind1,$ind2,$data) = @_;
   printf "%-9.9d %-3.3s%-1.1s%-1.1s L %s\n" , $recid, $field, $ind1, $ind2, $data;
}
