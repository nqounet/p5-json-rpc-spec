use strict;
use Test::More 0.98;

use JSON::RPC::Spec;
use JSON::XS;

my $rpc   = JSON::RPC::Spec->new;
my $coder = JSON::XS->new->utf8;

$rpc->register(
    'test.{matched}' => sub {
        my ($params, $matched) = @_;
        is ref $matched, 'HASH', 'matched hash';
        ok exists $matched->{matched}, 'exists matched key';
        ok !exists $matched->{'.callback'}, 'delete internal used key';
        return $matched;
    }
);

$rpc->register(
    'match' => sub {
        my ($params, $matched) = @_;
        is ref $matched, 'HASH', 'matched hash';
        ok !exists $matched->{'.callback'}, 'delete internal used key';
        return $matched;
    }
);

subtest 'placeholder' => sub {
    my $res
      = $rpc->parse('{"jsonrpc":"2.0","method":"test.ok","params":1,"id":1}');
    like $res, qr/"result":{"matched":"ok"}/, 'return ok' or diag explain $res;

    $res
      = $rpc->parse('{"jsonrpc":"2.0","method":"test.ok.ok","params":1,"id":1}');
    like $res, qr/"result":{"matched":"ok\.ok"}/, 'return ok.ok' or diag explain $res;
};

subtest 'normal match' => sub {
    my $res
      = $rpc->parse('{"jsonrpc":"2.0","method":"match","params":1,"id":1}');
    like $res, qr/"result":{}/, 'return empty hash' or diag explain $res;
};

subtest 'no  match' => sub {
    my $res
      = $rpc->parse('{"jsonrpc":"2.0","method":"test.ok/","params":1,"id":1}');
    like $res, qr/"Method not found"/, 'method not found' or diag explain $res;
};

done_testing;
