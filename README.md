[![Build Status](https://travis-ci.org/nqounet/p5-json-rpc-spec.png?branch=master)](https://travis-ci.org/nqounet/p5-json-rpc-spec)
# NAME

JSON::RPC::Spec - Yet another JSON-RPC 2.0 Implementation

# SYNOPSIS

    use strict;
    use JSON::RPC::Spec;

    my $rpc = JSON::RPC::Spec->new;
    $rpc->register(echo => sub { $_[0] });
    print $rpc->parse(
        '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!", "id": 1}'
    );    # -> {"jsonrpc":"2.0","result":"Hello, World!","id":1}

# DESCRIPTION

JSON::RPC::Spec is Yet another JSON-RPC 2.0 Implementation.

JSON format string execute registerd method

# FUNCTIONS

## new

    my $rpc = JSON::RPC::Spec->new;

create instance

## register

    # method => code refs
    $rpc->register(max => sub { max(@{$_[0]}) });

register method

## parse

    my $result = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
    );    # -> {"id":1,"result":11,"jsonrpc":"2.0"}

parse JSON and triggered method

# SEE ALSO

http://search.cpan.org/dist/JSON-RPC/

http://search.cpan.org/dist/JSON-RPC-Dispatcher/

http://search.cpan.org/dist/JSON-RPC-Common/

# LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

nqounet <mail@nqou.net>
