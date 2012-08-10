package Catmandu::Fix::holding;
use strict;
use Data::Dumper;
use Parse::RecDescent;

sub new {
    my $class = $_[0];
    my (@grammar) = <DATA>;
    my $parser = Parse::RecDescent->new(join("",@grammar));
    return bless {parser => $parser} , $class;
}

sub fix {
    my ($self, $data) = @_;
    
    return $data unless $data->{holding};

    if ($data->{source} eq 'ejn01') {
       $data = $self->sfx_holding($data);
    }
    else {
       $data = $self->default_holding($data);
    }

    $data;
}

sub sfx_holding {
    my ($self,$data) = @_;

    my $p_holding = "";
    for my $holding (@{ $data->{holding} }) {
        $p_holding .= ' ' . &_sfx_parse($holding);
    }

    $p_holding = &_unique($p_holding);
    my $h_holding = &_human($p_holding);

    $data->{holding} = $p_holding;
    $data->{holding_txt} = $h_holding;

    $data;
}

sub _sfx_parse {
    my $holding = shift;
    my $this_year = [ localtime ]->[5] + 1900;

    if ($holding =~ /Available from (\d+).*until (\d{4})/) {
        my $last_year = $2;
        return join(" " , ($1..$last_year));
    }
    elsif ($holding =~ /Available from (\d+).*Most recent (\d+).*year/) {
        my $last_year = $this_year - $2;
        return join(" " , ($1..$last_year));
    }
    elsif ($holding =~ /Available from (\d+)/) {
        return join(" " , ($1..$this_year));
    }
}

sub _unique {
    my $str = shift;
    my %h;
    foreach (split(" ",$str)) {
        $h{$_} = 1;
    }
    return join(" ", keys %h);
}

sub _human {
    my $str = shift;
    my $curryear   = [ localtime time]->[5] + 1900;
    my %h;

    foreach (split(" ",$str)) {
       $h{$_} = 1;
    }

    my $start = undef;
    my $prev  = undef;
    my $human = '';

    foreach (sort { $a <=> $b } keys %h) {
        if (! defined $start) {
           $start = $_;
        }
        elsif ($_ == $prev + 1) { }
        else {
           $human .= "$start - $prev ;";
           $start = $_;
        }
        $prev = $_;
    }

    $human .= "$start - $prev";

    $human =~ s{$curryear}{};

    return $human;
}

sub default_holding {
    my ($self,$data) = @_;
    my $identifier = $data->{_id};
    my $holding    = join(";", @{$data->{holding}});
    my $res        = $self->{parser}->startrule($holding);
    my $curryear   = [ localtime time]->[5] + 1900;
    
    # Collect all the parsed year hldings in an array of 'consecutive' years
    my %YEARS = ();
    foreach my $range (@$res) {
        next if (ref $range ne 'ARRAY' || @$range == 0);
        my $start = $range->[0];
        my $end   = $range->[1];
        $end = $start unless defined $end;
        $end = $curryear if $end eq 'NOW';
        for ($start..$end) { $YEARS{$_} = 1}
    }

    my @years = sort { $a <=> $b } keys %YEARS;

    # Translate the array of 'consecutive' years into an array of year ranges
    my @ranges;
    my $start = 0;
    my $prev  = 0;

    foreach my $year (@years) {
        $start = $year unless $start;
        if ($prev && $year - $prev > 1) {
          push(@ranges, $start eq $prev ? "$start" : "$start-$prev");
          $start = $year;
        }
        $prev = $year;
    }

    push(@ranges, $start eq $prev ? "$start" : "$start-$prev") if $start;

    my $years = join(" ", @years);
    my $range = join("; ", @ranges);

    $range =~ s{$curryear}{};

    print STDERR "record $identifier : failed to interpret '$holding'\n" if $range eq '';

    $data->{holding} = $years;
    $data->{holding_txt} = $range;
    
    $data;
}

1;

__DATA__
startrule:	item(s /;/) 
		    { $return = $item[1]; }

item:	    holding '-' holding junk(?) 
		    { $return = [ $item[1], $item[3] ]; }

		    |

		    holding '-' junk
		    { $return = [ $item[1] ]; }

		    |

		    holding '-' 
		    { $return = [ $item[1] , 'NOW' ]; }

		    |

		    holding 
		    { $return = [ $item[1] ]; }

		    |

		    <resync:[^;]*>

junk:		/[^;]+/
			
holding: 	stop(?) remark(?) volume(?) '(' publication_year except_or_range_year(?) ')' issue(?) 
		    { $return = $item{publication_year} } 

		    |

		    stop(?) remark(?) publication_year except_or_range_year(?) issue(?) 
		    { $return = $item{publication_year} }

volume: 	/[^#(;]+/

issue:      /[\w\.]+([-\/,:][\w\.]+)?/

stop:		/#/
	
except_or_range_year: /[-\/]\s*\d+/

publication_year:   /(16|17|18|19|20)\d{2}/ 

remark:	    	    /[^#:]+/ ':'
