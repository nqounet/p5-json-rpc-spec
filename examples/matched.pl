#!/usr/bin/env perl
use utf8;

package MyApp::Calc;
use 5.012;
use List::Util ();

sub jsonrpc_sum {
    my $class  = shift;
    my $params = shift;
    return List::Util::sum @{$params};
}

sub jsonrpc_max { List::Util::max @{$_[1]} }

package main;
use 5.012;
use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::RPC::Spec;

my $rpc = JSON::RPC::Spec->new;
$rpc->register(
    'list.{action}' => sub {
        my ($param, $matched) = @_;
        my $action  = 'jsonrpc_' . $matched->{action};
        return MyApp::Calc->$action($param);
    }
);

say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "list.sum", "params": [1,2,3,4,5], "id": 1}'
);

say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "list.max", "params": [1,7,3,4,5], "id": 1}'
);
