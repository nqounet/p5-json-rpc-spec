package JSON::RPC::Spec;
use strict;
use warnings;
use Carp ();

our $VERSION = "0.01";

use Class::Accessor::Lite rw => [qw(jsonrpc id is_batch is_notification)];
use JSON::XS;
use Router::Simple;
use Try::Tiny;
use JSON::RPC::Spec::Procedure;

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_DEBUG} || 0;

sub new {
    my $class = shift;
    my $args;
    $args->{coder} = JSON::XS->new->utf8;
    $args->{router} = Router::Simple->new;
    $args->{procedure}
      = JSON::RPC::Spec::Procedure->new(router => $args->{router});
    my $self = bless $args, $class;
    $self->jsonrpc('2.0');
    return $self;
}

# universal error routine
sub error {
    my ($self, $error) = @_;
    return +{
        jsonrpc => $self->jsonrpc,
        error   => $error,
        id      => $self->id
    };
}

sub rpc_invalid_request {
    my ($self) = @_;
    my $error = {
        code    => -32600,
        message => 'Invalid Request'
    };
    $self->is_notification(undef);
    $self->id(undef);
    return $self->error($error);
}

sub rpc_method_not_found {
    my ($self) = @_;
    my $error = {
        code    => -32601,
        message => 'Method not found'
    };
    return $self->error($error);
}

sub rpc_invalid_params {
    my ($self) = @_;
    my $error = {
        code    => -32602,
        message => 'Invalid params'
    };
    return $self->error($error);
}

sub rpc_internal_error {
    my ($self, @args) = @_;
    my $error = {
        code    => -32603,
        message => 'Internal error',
        @args
    };
    return $self->error($error);
}

sub rpc_parse_error {
    my ($self) = @_;
    my $error = {
        code    => -32700,
        message => 'Parse error'
    };
    $self->id(undef);
    return $self->error($error);
}

# parse JSON string
sub parse {
    my ($self, $json_string) = @_;
    warn qq{-- start parsing @{[$json_string]}\n} if DEBUG;
    my $coder = $self->{coder};
    unless (length $json_string) {
        return $coder->encode($self->rpc_invalid_request);
    }

    # JSON decode
    # rpc call with invalid JSON:
    # rpc call Batch, invalid JSON:
    my ($request, $has_error);
    try {
        $request = $coder->decode($json_string);
    }
    catch {
        $has_error = 1;
        $request   = $self->rpc_parse_error;
    };
    if ($has_error) {
        return $coder->encode($request);
    }

    # Batch mode flag
    if (ref $request eq 'ARRAY') {
        $self->is_batch(1);
    }
    else {
        $self->is_batch(0);
        $request = [$request];
    }

    # rpc call with an empty Array:
    unless (scalar @{$request}) {
        return $coder->encode($self->rpc_invalid_request);
    }

    # procedure call and create response
    my @response;
    for my $obj (@{$request}) {
        my $res = $self->{procedure}->parse($obj);

        # notification is ignore
        push @response, $res if $res;
    }
    my $result;
    if (@response) {
        if ($self->is_batch) {
            $result = $coder->encode(\@response);
        }
        else {
            $result = $coder->encode($response[0]);
        }
    }
    return $result;
}

# register method
sub register {
    my ($self, $name, $cb) = @_;
    $self->{router}->connect($name, {'.callback' => $cb}, {});
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

register method

=head2 parse

    my $result = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
    );    # -> {"id":1,"result":11,"jsonrpc":"2.0"}

parse JSON and triggered method

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
