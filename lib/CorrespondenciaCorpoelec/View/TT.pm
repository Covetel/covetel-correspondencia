package CorrespondenciaCorpoelec::View::TT;

use strict;
use base 'Catalyst::View::TT';
use Validaciones::Librerias;

__PACKAGE__->config({
    INCLUDE_PATH => [
        CorrespondenciaCorpoelec->path_to( 'root', 'src' ),
        CorrespondenciaCorpoelec->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    render_die   => 1,
	TEMPLATE_EXTENSION   => '.tt2',
    CATALYST_VAR  => 'Catalyst',
    ENCODING => 'UTF-8',
	expose_methods => [ qw/ fmt_fecha / ],

});

=head1 NAME

CorrespondenciaCorpoelec::View::TT - Catalyst TTSite View

=head1 SYNOPSIS

See L<CorrespondenciaCorpoelec>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

Joel Enrique Gomez Brito

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
sub fmt_fecha {
  my ($self, $c, $fecha) = @_;

   my $salida = fecha_usuario($fecha);

   return $salida;
 }

1;

