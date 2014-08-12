requires 'perl', '5.008001';
requires 'JSON::XS', 3.01;
requires 'Router::Simple', 0.15;
requires 'Try::Tiny', 0.22;

on 'test' => sub {
    requires 'Test::More', '0.98';
};
