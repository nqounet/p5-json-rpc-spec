use strict;
use Test::More;

eval {
    use Test::Perl::Critic;
};
plan skip_all => "Test::Perl::Critic is not installed." if $@;

all_critic_ok("lib");
