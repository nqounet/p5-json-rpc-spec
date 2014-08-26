package JSON::RPC::Spec::Common;
use strict;
use warnings;
use Carp ();

use JSON::MaybeXS qw(JSON);

use Moo::Role;

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_DEBUG} || 0;

has _callback_key => (
    is      => 'ro',
    default => '.callback'
);
has coder => (
    is      => 'ro',
    default => sub { JSON->new->utf8 },
    isa     => sub {
        my $self = shift;
        $self->can('encode') or Carp::croak('method encode required.');
        $self->can('decode') or Carp::croak('method decode required.');
    },
);
has jsonrpc => (
    is      => 'ro',
    default => '2.0'
);
has id              => (is => 'rw');
has is_notification => (is => 'rw');

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
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Spec::Common - common class of JSON::RPC::Spec

=head1 FUNCTIONS

=head2 coder

JSON Encoder/Decoder. similar L<< JSON >>.

=head2 jsonrpc

JSON-RPC version (2.0 is default)

=head2 id

=head2 is_notification

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
