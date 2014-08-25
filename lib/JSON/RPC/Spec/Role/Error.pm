package JSON::RPC::Spec::Role::Error;
use strict;
use warnings;
use Carp ();

use Moo::Role;

requires qw(jsonrpc id is_notification);

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

1;
