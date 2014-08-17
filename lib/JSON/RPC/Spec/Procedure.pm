package JSON::RPC::Spec::Procedure;
use strict;
use warnings;
use Carp ();

use parent 'JSON::RPC::Spec';
use Try::Tiny;

use constant DEBUG => $ENV{PERL_JSON_RPC_SPEC_PROCEDURE_DEBUG} || 0;

sub new {
    my $class = shift;
    my $args = @_ == 1 ? $_[0] : +{@_};
    if (!exists $args->{router}) {
        Carp::confess 'router requred';
    }
    my $self = bless $args, $class;
    return $self;
}

sub parse {
    my ($self, $obj) = @_;
    if (ref $obj ne 'HASH' or !exists $obj->{jsonrpc}) {
        return $self->_rpc_invalid_request;
    }
    $self->is_notification(!exists $obj->{id} and $obj->{jsonrpc} eq '2.0');
    $self->jsonrpc($obj->{jsonrpc});
    $self->id($obj->{id});
    my $method = $obj->{method};

    # rpc call with invalid Request object:
    # rpc call with an invalid Batch (but not empty):
    # rpc call with invalid Batch:
    if ($method eq '' or $method =~ m!\A\.|\A[0-9]+\z!) {
        return $self->_rpc_invalid_request;
    }
    my ($result, $error);
    try {
        $result = $self->trigger($method, $obj->{params});
    }
    catch {
        my $e = $_;
        if ($e =~ m!rpc_method_not_found!) {
            $error = $self->_rpc_method_not_found;
        }
        else {
            $error = $self->_rpc_internal_error(data => $e);
        }
    };
    if ($self->is_notification) {
        return;
    }
    if ($error) {
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
    my $router  = $self->{router};
    my $matched = $router->match($name);

    # rpc call of non-existent method:
    unless ($matched) {
        Carp::confess 'rpc_method_not_found';
    }
    my $cb = delete $matched->{'.callback'};
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
