package Catmandu::Fix::meercat;
use strict;
use subs qw(data data_hash);

sub new {
    my $class = $_[0];
    return bless {} , $class;
}

sub fix {
    my ($self, $data) = @_;

    $data = &fix_index($data);
    
    $data;
}

sub fix_index {
    my $data = $_[0];
    my $record = $data->{record};
    
    my @fulltext = ($data->{source});
    
    for my $field (@$record) {
        my ($tag,$ind1,$ind2,@sf) = @$field;
        my $val = $sf[1];
        
        if (0) {}
        elsif ($tag eq '005') {
            $data->{fDATE} = $val;
        }
        elsif ($tag eq '008') {
            $val =~ s{\^}{0}g;
            my $year    = substr($val,7,4);
            my $period  = substr($val,7,2);
            my $lang    = substr($val,35,3);

            $data->{year}   = $year if $year =~ /^\d{4}$/;
            $data->{period} = $period;
            $data->{lang}   = $lang;
            delete $data->{year} if $data->{year} == 0;
            delete $data->{period} if $data->{period} == 0;

            push @{$data->{all}} , $year if $year;
        }
        elsif ($tag eq '009') {
            $data->{collection} = $val;
        }
        elsif ($tag eq '020') {
            $val = join "", data('a',@sf);
            push @{$data->{isbn}} , $val;
            push @{$data->{isxn}} , $val;
        }
        elsif ($tag eq '022') {
            $val = join "", data('a',@sf);
            push @{$data->{issn}} , $val;
            push @{$data->{isxn}} , $val;
        }
        elsif ($tag eq '100') {
            $val = join " ", data("abd",@sf);
            push @{$data->{author}} , $val;
        }
        elsif ($tag eq '111') {
            $val = join " ", data("abd",@sf);
            push @{$data->{author}} , $val;
        }
        elsif ($tag eq '130') {
            $val = join " ", data("abd",@sf);
            push @{$data->{author}} , $val;
        }
        elsif ($tag eq '170') {
            $val = join " ", data("abd",@sf);
            push @{$data->{author}} , $val;
        }
        elsif ($tag eq '245') {
            $val = join " ", data(undef,@sf);
            $data->{title} = $val unless $data->{title};
            
            my $sort_title = substr(lc $val, 0, 80);
            $sort_title =~ s/\s+//g;
            $data->{title_sort} = $sort_title;
        }
        elsif ($tag eq '650') {
            my @region = data("z",@sf);
            $val = $region[-1];
            push @{$data->{region}} , $val;
        }
        elsif ($tag eq '651') {
            $val = join " ", data("a",@sf);
            push @{$data->{region}} , $val;
        }
        elsif ($tag eq '700') {
            $val = join " ", data("abd",@sf);
            push @{$data->{author}} , $val;
        }
        elsif ($tag eq '710') {
            $val = join " ", data("abd",@sf);
            push @{$data->{author}} , $val;
        }
        elsif ($tag eq '720') {
            $val = join " ", data("abd",@sf);
            push @{$data->{author}} , $val;
        }
        elsif ($tag eq '852') {
            my $c = data_hash(@sf);
            push @{$data->{holding}}    , $c->{a} if $c->{a};
            push @{$data->{department}} , $c->{b} if $c->{b};
            push @{$data->{library}}    , $c->{c} if $c->{c};
            push @{$data->{location}}   , $c->{j} if $c->{j};
            push @{$data->{faculty}}    , $c->{x} if $c->{x};
            $val = join " ", values %$c;
        }
        elsif ($tag eq '856') {
            $val = join " ", data(undef,@sf);
            push @fulltext , $val;

            my $link = join "", data('u',@sf);
            my $path = join "", data('d',@sf);
            my $file = join "", data('f',@sf);

            if ($path && $file) {
                $data->{content} = "$path/$file";
            }
            else {
                $data->{content} = $link;
            }
        }
        elsif ($tag eq '866' && $data->{source} eq 'ejn01') {
            $val = join " ", data('a',@sf);
            push @{$data->{holding}} , $val;
        }
        elsif ($tag eq '920') {
            $val = join "", data('a',@sf);
            $data->{type} = $val;
        }
        elsif ($tag eq 'CAT') {
            $val = join "", data('f',@sf);
            $data->{cid} = $val if $val;
        }
        elsif ($tag eq 'STA') {
            $val = join "", data('a',@sf);
            $data->{perm} = $val;
        }
        elsif ($tag eq 'Z30') {
            $val = join " ", data("82",@sf);
            $val =~ s{(\S+) (\S+)}{$2$1};
            push @{$data->{created}} , $val;
        }
        elsif ($tag !~ /^[0-9]/) {
        }
        else {
            $val = join " ", data(undef,@sf);
        }
        
        $data->{fulltext} = grep(/pug01|bkt01|ebk01|ejn01|dnl01|gtb01|ecco01|hth01|Full text/,@fulltext) ? 1 : 0;
        
        push @{$data->{all}} , $val if $val;
    }
    
    $data;
}

sub data {
    my ($code_match,@data) = @_;
    my @res;
    for (my $i = 2 ; $i < @data ; $i+=2) {
        my $code = $data[$i];
        my $val  = $data[$i+1];
        push(@res,$val) if (!defined $code_match || index($code_match,$code) != -1);
    }
    return @res;
}

sub data_hash {
    my (@data) = @_;
    my %res;
    for (my $i = 2 ; $i < @data ; $i+=2) {
        my $code = $data[$i];
        my $val  = $data[$i+1];
        $res{$code} = $val
    }
    return \%res;
}

1;
