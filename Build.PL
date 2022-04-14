use strict;
use warnings;
use Module::Build;

$ENV{'PERL_MB_OPT'} = '--install-base=/usr'; # I could not make this work via the parameters below :/
$ENV{'DEB_BUILD_OPTIONS'}='nocheck';

use lib '../tm2_base/lib';
use lib '../templescript/lib';

my $debian = Module::Build->subclass(
    class => "Module::Build::Debian",
    code => <<'SUBCLASS' );

sub DEBVERSION {
    return 5;
}

sub ACTION_debian {
    my $self = shift;

    $self->depends_on("dist");
    $self->depends_on("distdir");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{   DEB_BUILD_OPTIONS=nocheck dh-make-perl --build --notest --version=$version-$debversion TM2-Google-$version } );

}
sub ACTION_inject {
    my $self = shift;

    $self->depends_on("debian");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ scp libtm2-google-perl_${version}-${debversion}_all.deb packages.devc.at:packages/ } );
    foreach (qw( bullseye stretch ) ) {# squeeze wheezy jessie 
        $self->do_system(qq{ ssh packages.devc.at -t -Y reprepro --ask-passphrase -b /var/www/packages/data/dists/ includedeb $_ packages/libtm2-google-perl_${version}-${debversion}_all.deb });
    }
}
SUBCLASS


my $builder = $debian->new(
    module_name         => 'TM2::Google',
    license             => 'perl',
    dist_author         => q{Robert Barta <rho@devc.at>},
    dist_version_from   => 'lib/TM2/Google.pm',
    configure_requires  => { 'Module::Build' => 0 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'TM2::TempleScript'   => 0,
    },
    add_to_cleanup      => [ 'TM2-Google-*' ],
    create_makefile_pl => 'traditional',
    onto_files          => {
                             'ontologies/google-site-verification.ts'        => 'ontologies/google-site-verification.ts',
    },
    install_path        => { 'ontologies' => '/usr/share/templescript/ontologies' },
);

$builder->add_build_element('onto');
$builder->create_build_script();
