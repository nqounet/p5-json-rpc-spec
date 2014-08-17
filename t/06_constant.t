use strict;
use Test::More 0.98;

BEGIN {
    $ENV{PERL_JSON_RPC_SPEC_DEBUG} = 1;
    $ENV{PERL_JSON_RPC_SPEC_PROCEDURE_DEBUG} = 1;
}

use_ok $_ for qw(
    JSON::RPC::Spec
    JSON::RPC::Spec::Procedure
);

done_testing;
