package JSON::RPC::Spec;
use strict;
use warnings;
use Carp ();

our $VERSION = "0.03";

use Class::Accessor::Lite rw =>
  [qw(jsonrpc id is_batch is_notification parsed)];
use JSON::MaybeXS qw(JSON);
use Router::Simple;
use Try::Tiny;
use JSON::RPC::Spec::Procedure;

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_DEBUG} || 0;

sub new {
    my $class = shift;
    my $args = @_ == 1 ? $_[0] : +{@_};
    if (!exists $args->{coder}) {
        $args->{coder} = JSON->new->utf8;
    }
    if (!exists $args->{router}) {
        $args->{router} = Router::Simple->new;
    }
    $args->{procedure}
      = JSON::RPC::Spec::Procedure->new(router => $args->{router});
    my $self = bless $args, $class;
    $self->jsonrpc('2.0');
    return $self;
}

# universal error routine
sub _error {
    my ($self, $error) = @_;
    return +{
        jsonrpc => $self->jsonrpc,
        error   => $error,
        id      => $self->id
    };
}

sub _rpc_invalid_request {
    my ($self) = @_;
    my $error = {
        code    => -32600,
        message => 'Invalid Request'
    };
    $self->is_notification(undef);
    $self->id(undef);
    return $self->_error($error);
}

sub _rpc_method_not_found {
    my ($self) = @_;
    my $error = {
        code    => -32601,
        message => 'Method not found'
    };
    return $self->_error($error);
}

sub _rpc_invalid_params {
    my ($self) = @_;
    my $error = {
        code    => -32602,
        message => 'Invalid params'
    };
    return $self->_error($error);
}

sub _rpc_internal_error {
    my ($self, @args) = @_;
    my $error = {
        code    => -32603,
        message => 'Internal error',
        @args
    };
    return $self->_error($error);
}

sub _rpc_parse_error {
    my ($self) = @_;
    my $error = {
        code    => -32700,
        message => 'Parse error'
    };
    $self->id(undef);
    return $self->_error($error);
}

sub _parse_json {
    my ($self, $json_string) = @_;
    unless (length $json_string) {
        return $self->_rpc_invalid_request;
    }

    # JSON decode
    # rpc call with invalid JSON:
    # rpc call Batch, invalid JSON:
    my ($req, $has_error);
    try {
        $req = $self->{coder}->decode($json_string);
    }
    catch {
        $has_error = 1;
        $req       = $self->_rpc_parse_error;
    };
    if ($has_error) {
        return $req;
    }
    $self->parsed($req);
    return;
}

sub _parse {
    my ($self) = @_;

    my $req = $self->parsed;

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
        my $res = $self->{procedure}->parse($obj);

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
    warn qq{-- start parsing @{[$json_string]}\n} if DEBUG;
    my $result = $self->_parse_json($json_string);
    return $result if $result;
    return $self->_parse;
}

# parse JSON string to JSON string
sub parse {
    my ($self, $json_string) = @_;
    my $result = $self->parse_without_encode($json_string);
    return unless $result;
    return $self->{coder}->encode($result);
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
    $self->{router}->connect($pattern, {'.callback' => $cb}, {});
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
