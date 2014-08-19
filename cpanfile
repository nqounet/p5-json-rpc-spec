requires 'perl', '5.008001';
requires 'Class::Accessor::Lite';
requires 'JSON::MaybeXS';
requires 'Router::Simple';
requires 'Try::Tiny';

recommends 'Cpanel::JSON::XS';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
