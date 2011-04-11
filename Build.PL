use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SIAM',
    license             => 'mit',
    dist_author         => q{Stanislav Sinyagin <ssinyagin@k-open.com>},
    dist_version_from   => 'lib/SIAM.pm',
    build_requires => {
        'Test::More' => 0,
        'YAML' => 0,
        'Log::Handler' => 0,
        'Digest::MD5' => 0,
    },
    requires => {
    },
    recommends => {
        'YAML' => 0,
        'Log::Handler' => 0,
        'Digest::MD5' => 0,
    },
    add_to_cleanup      => [ 'SIAM-*' ],
);

$builder->create_build_script();
