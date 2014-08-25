package JSON::RPC::Spec::Procedure;
use strict;
use warnings;
use Carp ();

use Moo;
use Try::Tiny;

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_PROCEDURE_DEBUG} || 0;

has router => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        my $self = shift;
        $self->can('match') or Carp::croak('method match required.');
    },
);
has jsonrpc => (
    is      => 'ro',
    default => '2.0',
);
has id              => (is => 'rw');
has is_notification => (is => 'rw');

with 'JSON::RPC::Spec::Common';

sub parse {
    my ($self, $obj) = @_;
    if (ref $obj ne 'HASH') {
        return $self->_rpc_invalid_request;
    }
    $self->is_notification(!exists $obj->{id});
    $self->id($obj->{id});
    my $method = $obj->{method} || '';

    # rpc call with invalid Request object:
    # rpc call with an invalid Batch (but not empty):
    # rpc call with invalid Batch:
    if ($method eq '' or $method =~ m!\A\.|\A[0-9]+\z!) {
        return $self->_rpc_invalid_request;
    }
    my ($result, $err);
    try {
        $result = $self->trigger($method, $obj->{params});
    }
    catch {
        $err = $_;
        warn qq{-- error : @{[$err]} } if DEBUG;
    };
    if ($self->is_notification) {
        return;
    }
    if ($err) {
        my $error;
        if ($err =~ m!rpc_method_not_found!) {
            $error = $self->_rpc_method_not_found;
        }
        elsif ($err =~ m!rpc_invalid_params!) {
            $error = $self->_rpc_invalid_params;
        }
        else {
            $error = $self->_rpc_internal_error(data => $err);
        }
        return $error;
    }
    return +{
        jsonrpc => $self->jsonrpc,
        result  => $result,
        id      => $self->id
    };
}

# trigger registered method
sub trigger {
    my ($self, $name, $params) = @_;
    my $router  = $self->router;
    my $matched = $router->match($name);

    # rpc call of non-existent method:
    unless ($matched) {
        Carp::confess 'rpc_method_not_found';
    }
    my $cb = delete $matched->{$self->callback_key};
    return $cb->($params, $matched);
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Spec::Procedure - Subclass of JSON::RPC::Spec

=head1 SYNOPSIS

    use strict;
    use Router::Simple;
    use JSON::RPC::Spec::Procedure;

    my $router = Router::Simple->new;
    $router->connect(
        echo => {
            '.callback' => sub { $_[0] }
        }
    );
    my $proc = JSON::RPC::Spec::Procedure->new(router => $router);
    my $res = $proc->parse(
        {
            jsonrpc => '2.0',
            method  => 'echo',
            params  => 'Hello, World!',
            id      => 1
        }
    ); # return hash ->
       #    {
       #        jsonrpc => '2.0',
       #        result  => 'Hello, World!',
       #        id      => 1
       #    },

=head1 DESCRIPTION

JSON::RPC::Spec is Subclass of JSON::RPC::Spec.

=head1 FUNCTIONS

=head2 new

=head2 parse

=head2 trigger

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
