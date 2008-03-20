use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Pastebin::CSSStandardsOrg::Retrieve',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/Pastebin/CSSStandardsOrg/Retrieve.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                     => 1.04,
        'Devel::TakeHashArgs'      => 0.002,
        'URI'                      => 1.35,
        'LWP::UserAgent'           => 2.036,
        'HTML::TokeParser::Simple' => 3.15,
        'HTML::Entities'           => 1.35,
        'Class::Data::Accessor'    => 0.04001,
    },
    add_to_cleanup      => [ 'WWW-Pastebin-CSSStandardsOrg-Retrieve-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
