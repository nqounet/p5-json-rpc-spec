use strict;
use Test::More 0.98;

use Router::Simple;
use JSON::RPC::Spec::Procedure;

my $router = Router::Simple->new;
$router->connect(
    echo => {
        '.callback' => sub { $_[0] }
    }
);

my $proc = JSON::RPC::Spec::Procedure->new(router => $router);
ok $proc,     'new';
isa_ok $proc, 'JSON::RPC::Spec::Procedure';

subtest 'parse' => sub {
    my $res = $proc->parse(
        {
            jsonrpc => '2.0',
            method  => 'echo',
            params  => 'Hello, World!',
            id      => 1
        }
    );

    is_deeply $res,
      {
        jsonrpc => '2.0',
        result  => 'Hello, World!',
        id      => 1
      },
      'result'
      or diag explain $res;
};

subtest 'trigger' => sub {
    my $params = 'Hello, trigger!';
    my $res = $proc->trigger('echo', $params);
    is $res, $params, 'trigger' or diag explain $res;
};

subtest 'router missing' => sub {
    my $res;
    eval { $res = JSON::RPC::Spec::Procedure->new; };
    ok $@;
    like $@, qr/router requred/, 'router requred';
};

done_testing;
