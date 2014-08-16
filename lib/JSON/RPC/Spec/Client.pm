package JSON::RPC::Spec::Client;
use strict;
use warnings;
use Carp ();

use Class::Accessor::Lite rw => [qw(jsonrpc)];

sub new {
    my $class = shift;
    my $args  = @_ == 1 ? $_[0] : +{@_};
    my $self  = bless $args, $class;
    $self->jsonrpc('2.0');
    return $self;
}

sub compose {
    my ($self, $method, $params, $id) = @_;
    my @args;
    if (defined $id) {
        @args = (id => $id);
    }
    return $self->{coder}->encode(
        {
            jsonrpc => $self->jsonrpc,
            method  => $method,
            params  => $params,
            @args
        }
    );
}

1;
