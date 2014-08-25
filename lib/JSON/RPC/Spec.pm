package JSON::RPC::Spec;
use strict;
use warnings;
use Carp ();

our $VERSION = "0.03";

use JSON::MaybeXS qw(JSON);
use Router::Simple;
use Try::Tiny;
use JSON::RPC::Spec::Procedure;

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_DEBUG} || 0;

use Moo;

has coder => (
    is      => 'ro',
    default => sub { JSON->new->utf8 },
    isa     => sub {
        my $self = shift;
        $self->can('encode') or Carp::croak('method encode required.');
        $self->can('decode') or Carp::croak('method decode required.');
    },
);
has router => (
    is      => 'ro',
    default => sub { Router::Simple->new },
    isa     => sub {
        my $self = shift;
        $self->can('match') or Carp::croak('method match required.');
    },
);
has procedure => (
    is   => 'ro',
    lazy => 1,
    default =>
      sub { JSON::RPC::Spec::Procedure->new(router => shift->router) },
);
has jsonrpc => (
    is      => 'ro',
    default => '2.0',
);
has id              => (is => 'rw');
has is_batch        => (is => 'rw');
has is_notification => (is => 'rw');
has content         => (is => 'rw');

with 'JSON::RPC::Spec::Common';

sub _parse_json {
    my ($self) = @_;
    warn qq{-- start parsing @{[$self->content]}\n} if DEBUG;

    unless (length $self->content) {
        return $self->_rpc_invalid_request;
    }

    # JSON decode
    # rpc call with invalid JSON:
    # rpc call Batch, invalid JSON:
    my ($req, $has_error);
    try {
        $req = $self->coder->decode($self->content);
    }
    catch {
        $has_error = 1;
        $req       = $self->_rpc_parse_error;
    };
    if ($has_error) {
        return $req;
    }

    # Batch mode flag
    if (ref $req eq 'ARRAY') {
        $self->is_batch(1);
    }
    else {
        $self->is_batch(0);
        $req = [$req];
    }

    # rpc call with an empty Array:
    unless (scalar @{$req}) {
        return $self->_rpc_invalid_request;
    }

    # procedure call and create response
    my @response;
    for my $obj (@{$req}) {
        my $res = $self->procedure->parse($obj);

        # notification is ignore
        push @response, $res if $res;
    }
    if (@response) {
        if ($self->is_batch) {
            return [@response];
        }
        else {
            return $response[0];
        }
    }
    return;
}

# parse JSON string to hash
sub parse_without_encode {
    my ($self, $json_string) = @_;
    $self->content($json_string);
    return $self->_parse_json;
}

# parse JSON string to JSON string
sub parse {
    my ($self, $json_string) = @_;
    $self->content($json_string);
    my $result = $self->_parse_json;
    return unless $result;
    return $self->coder->encode($result);
}

# register method
sub register {
    my ($self, $pattern, $cb) = @_;
    if (!defined $pattern) {
        Carp::croak('pattern required');
    }
    if (ref $cb ne 'CODE') {
        Carp::croak('code required');
    }
    $self->router->connect($pattern, {$self->callback_key => $cb}, {});
    return $self;
}


1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Spec - Yet another JSON-RPC 2.0 Implementation

=head1 SYNOPSIS

    use strict;
    use JSON::RPC::Spec;

    my $rpc = JSON::RPC::Spec->new;
    $rpc->register(echo => sub { $_[0] });
    print $rpc->parse(
        '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!", "id": 1}'
    );    # -> {"jsonrpc":"2.0","result":"Hello, World!","id":1}

=head1 DESCRIPTION

JSON::RPC::Spec is Yet another JSON-RPC 2.0 Implementation.

JSON format string execute registerd method

=head1 FUNCTIONS

=head2 new

    my $rpc = JSON::RPC::Spec->new;

create instance

=head2 register

    # method => code refs
    use List::Util qw(max);
    $rpc->register(max => sub { max(@{$_[0]}) });

    # method matching via Router::Simple
    $rpc->register('myapp.{action}' => sub {
        my ($params, $match) = @_;
        my $action = $match->{action};
        return MyApp->new->$action($params);
    });

register method.

=head2 parse

    my $result = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
    );    # returns JSON encoded string -> {"id":1,"result":11,"jsonrpc":"2.0"}

parse JSON and triggered method. returns JSON encoded string.

=head2 parse_without_encode

    my $result = $rpc->parse_without_encode(
        '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
    );    # returns hash -> {id => 1, result => 11, jsonrpc => '2.0'}

parse JSON and triggered method. returns HASH.

=head1 DEBUGGING

You can set the C<PERL_JSON_RPC_SPEC_DEBUG> environment variable to get some advanced diagnostics information printed to C<STDERR>.

    PERL_JSON_RPC_SPEC_DEBUG=1

=head1 SEE ALSO

http://search.cpan.org/dist/JSON-RPC/

http://search.cpan.org/dist/JSON-RPC-Dispatcher/

http://search.cpan.org/dist/JSON-RPC-Common/

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
