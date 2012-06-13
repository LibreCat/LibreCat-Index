package Catmandu::Fix::matches;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Data::Dumper;
use Moo;

has path    => (is => 'ro', required => 1);
has key     => (is => 'ro', required => 1);
has search  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $search) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, search => $search);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $search  = $self->search; 

    my @matches = grep ref, data_at($self->path, $data, key => $key);

    for my $match (@matches) {
        if (is_array_ref($match)) {
            is_integer($key) || next;
            my $val = $match->[$key];
            $match->[$key] = ($val =~ m{$search}) ? 1 : 0 if is_string($val);
        } else {
            my $val = $match->{$key};
            $match->{$key} = ($val =~ m{$search}) ? 1 : 0 if is_string($val);
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::matches - match string using regex expressions

=head1 SYNOPSIS

   # Replace by 1 or 0 when year contains a 19
   matches('year','19');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;