use strict;
use Test::More 0.98;

use JSON::RPC::Spec;
use JSON::XS;

my $rpc   = new_ok 'JSON::RPC::Spec';
my $coder = JSON::XS->new->utf8;

subtest 'register' => sub {
    my $register = $rpc->register(echo => sub { $_[0] });
    ok $register, 'method register';
    is ref $register, 'JSON::RPC::Spec', 'instance of `JSON::RPC::Spec`'
      or diag explain $register;
    $rpc->register(emit_error => sub {die});
};

subtest 'parse' => sub {
    for my $content ('Hello', [1, 2], {foo => 'bar'}) {
        my $id          = time;
        my $json_string = $coder->encode(
            {
                jsonrpc => '2.0',
                id      => $id,
                method  => 'echo',
                params  => $content
            }
        );
        my $res = $rpc->parse_without_encode($json_string);
        ok $res, 'parse_without_encode ok' or diag explain $json_string;
        is_deeply $res,
          {
            jsonrpc => '2.0',
            id      => $id,
            result  => $content
          },
          'result'
          or diag explain $res;
    }
};

subtest 'register error' => sub {
    my $register;
    eval { $register = $rpc->register };
    ok $@, 'register requires params';
    like $@, qr/pattern required/ or diag explain $@;

    eval { $register = $rpc->register('pattern') };
    ok $@, 'register requires code reference';
    like $@, qr/code required/ or diag explain $@;
};

subtest 'parse error' => sub {
    my $res;
    $res = $rpc->parse_without_encode('');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is $res->{error}{message}, 'Invalid Request', '"" -> Invalid Request';

    $res = $rpc->parse_without_encode('[');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is $res->{error}{message}, 'Parse error', '"[" -> Parse error';

    $res = $rpc->parse_without_encode('[]');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is $res->{error}{message}, 'Invalid Request', '"[]" -> Invalid Request';

    $res = $rpc->parse_without_encode('[{}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      '"[{}]" -> Invalid Request';

    $res
      = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":"","id":1}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method empty -> Invalid Request';

    $res = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":""}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'invalid method -> ignore notification';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":".anything","id":1}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method start at dot -> Invalid Request';

    $res
      = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":".anything"}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'invalid method -> ignore notification';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"123456789","id":1}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method number only -> Invalid Request';

    $res
      = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":"123456789"}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method start at dot -> Invalid Request';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"404notfount","id":1}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Method not found', 'Method not found';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"404notfount"}]');
    ok !$res, 'Method not found -> notification';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"emit_error","id":1}]');
    is ref $res, 'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Internal error', 'Internal error';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"emit_error"}]');
    ok !$res, 'Internal error -> notification';
};

done_testing;
