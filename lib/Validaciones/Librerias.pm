package Validaciones::Librerias;
use DateTime::Format::Strptime;
use File::Copy;
use Switch;

require Exporter;

$listaunidades =

@ISA = qw(Exporter);
@EXPORT = qw(fecha_usuario usuario_fecha trim upload_attachment prioridad);

sub fecha_usuario {
	my $fecha = shift;
		if ( $fecha ){
			my $formato_entrada = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' );
			my $formato_salida = '%d/%m/%Y';

			my $dt = $formato_entrada->parse_datetime( $fecha );
			if ( $dt ) {
				return $dt->strftime($formato_salida);
			}else{
				return $fecha;
			}
		}else{
			return '';
		}
}

sub usuario_fecha {
	my $fecha = shift;

	if ( $fecha ) {
		my $formato_entrada = DateTime::Format::Strptime->new( pattern => '%d/%m/%Y' );
		my $formato_salida = '%Y-%m-%d';

		my $dt = $formato_entrada->parse_datetime( $fecha );
		if ( $dt ){
			return $dt->strftime($formato_salida);
		}else{
			return $fecha;
		}

	}else{
		return '';
	}
}

=head2 trim
    Limpia espacios al principio y al final de la cadena
=cut

sub trim {
    my $cadena = shift;
    $cadena =~ s/^\s+//;
    $cadena =~ s/\s+$//;
    return $cadena;
}

sub upload_attachment {
	my ( $ticket, $upload ) = @_;

	my $dir =  $upload->tempname . ".dir$$";
	my $n   =  "$dir/" . $upload->filename;
	mkdir $dir;
	#$upload->link_to($n);
	
	my $fh = $upload->fh;
	copy($fh, $n);		
	$ticket->comment( message => "esto es un mensaje" , attachments=>[$n] );
	unlink $n;
	rmdir $dir;
}

sub prioridad {
	my $prioridad = shift;

	switch ($prioridad) {
		case "Simple" { return "1" }
		case "Urgente" { return "2" }
		case "Confidencial" { return "3" }
		case "Urgente y Confidencial" { return "4" }
	}
}
