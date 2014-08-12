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
        my $result = $rpc->parse($json_string);
        ok $result, 'parse ok';
        is_deeply $coder->decode($result),
          +{
            jsonrpc => '2.0',
            id      => $id,
            result  => $content
          },
          'result'
          or diag explain $result;
    }
};

subtest 'empty string' => sub {
    my $result = $rpc->parse('');
    ok $result, 'method parse';
    is_deeply $coder->decode($result),
      +{
        jsonrpc => '2.0',
        id      => undef,
        error   => {
            code    => -32600,
            message => 'Invalid Request'
        }
      },
      'empty request'
      or diag explain $result;
};

subtest 'result is empty string' => sub {
    my $id          = time;
    my $json_string = $coder->encode(
        {
            jsonrpc => '2.0',
            id      => $id,
            method  => 'echo',
            params  => ''
        }
    );
    my $result = $rpc->parse($json_string);
    ok $result, 'method parse';
    is_deeply $coder->decode($result),
      +{
        jsonrpc => '2.0',
        id      => $id,
        result  => ''
      },
      'result is empty string'
      or diag explain $result;
};

subtest 'custom error' => sub {
    $rpc->register(echo_die => sub { die $_[0] });
    for my $content ("Hello\n", [1, 2], {foo => 'bar'}) {
        my $id          = time;
        my $json_string = $coder->encode(
            {
                jsonrpc => '2.0',
                id      => $id,
                method  => 'echo_die',
                params  => $content
            }
        );
        my $result = $rpc->parse($json_string);
        ok $result, 'parse ok';
        is_deeply $coder->decode($result),
          +{
            jsonrpc => '2.0',
            id      => $id,
            error   => {
                code    => -32603,
                message => 'Internal error',
                data    => $content
            }
          },
          'result has error object'
          or diag explain $result;
    }
};

done_testing;
