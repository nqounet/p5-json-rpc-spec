requires 'perl', '5.008001';
requires 'JSON::XS', 3.01;
requires 'Router::Simple';
requires 'Try::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

