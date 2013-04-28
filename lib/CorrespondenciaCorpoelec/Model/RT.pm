package CorrespondenciaCorpoelec::Model::RT;
use Moose;
use namespace::autoclean;
use RT::Client::REST;
use RT::Client::REST::Ticket;
use RT::Client::REST::Exception;
use Validaciones::Librerias qw( upload_attachment usuario_fecha fecha_usuario );
use Try::Tiny;
use Encode;

extends 'Catalyst::Model';

sub conectar {
 my ( $self ) = @_;

	my $rt = RT::Client::REST->new(
				server => CorrespondenciaCorpoelec->config->{server},
				timeout => 30
			);
	
	return $rt;
}

sub auth {
	my ( $self, $user, $pass ) = @_;

	my $conexion = $self->conectar();
	try {
		$conexion->login(
				  username => $user,
				  password  => $pass
				);
		return $conexion;

	} catch {
		if ( m/Incorrect username or password/ ) {

			return "Usuario o contrase&ntilde;a invalido";
		}else{
			return "Error: $_";
		}
	};
}

sub save_correspondencia {
	my ( $self, %datos ) = @_;

	my $rt = $self->auth( $datos{user}, $datos{pass} );
	
	$DB::single=1;
	try {
	    my $ticket = RT::Client::REST::Ticket->new(
									rt 	 =>  $rt,
									owner 	 =>  $datos{user},
									queue 	 =>  $datos{cola},
									owner  =>  $datos{user},
									status 	 =>  "new",
									priority =>  $datos{prioridad},
									subject  =>  uc($datos{asunto}),
									cf => {
											remitente 		=>  uc($datos{remitente}),
											organismo		=>  uc($datos{organismo}),
											fecha_recepcion =>  usuario_fecha($datos{fecha_recepcion}),
											anexo 		  	=>  uc($datos{anexos}),
											tipo			=>  uc($datos{tipo}),
											respuesta 		=>  uc($datos{respuesta}),
											fecha_respuesta	=>  usuario_fecha($datos{fecha_respuesta}),
											destinatario    =>  uc($datos{destinatario}),
											cargado			=>  $datos{user},
											observaciones 	=>  uc($datos{obs}),
											cargo_remitente =>  uc($datos{cargo_remitente}),
											remitido		=>  uc($datos{remitido})
										  },
					  )->store();

		upload_attachment( $ticket, $datos{adjunto} );
		return "Correspondencia Guardada Exitosamente | <a href='/correspondencia/etiqueta/".$ticket->id."' class='verEtiqueta'>Imprimir Etiqueta</a>";
	} catch {
		return $_;
	};
}


sub save_envio {
	my ( $self, %datos ) = @_;

	my $rt = $self->auth( $datos{user}, $datos{pass} );
	
	$DB::single=1;
	try {
	    my $ticket = RT::Client::REST::Ticket->new(
							rt 	 =>  $rt,
							owner 	 =>  $datos{user},
							queue 	 =>  $datos{cola},
							owner  =>  $datos{user},
							status 	 =>  "new",
							priority =>  $datos{prioridad},
							subject  =>  uc($datos{asunto}),
							cf => {
									remitente	=>  uc($datos{remitente}),
									cargo_remitente =>  $datos{cargo_remitente},
									numero_doc	=>  uc($datos{numero_doc}),
									destinatario	=>  uc($datos{destinatario}),
									cargo_destinatario=>  uc($datos{cargo_destinatario}),
									fecha_envio	=>  usuario_fecha($datos{fecha_envio}),
									cargado		=>  $datos{user},
									resumen 	=>  uc($datos{resumen}),
								  },
					  )->store();

		upload_attachment( $ticket, $datos{adjunto} );
		return "Correspondencia Guardada Exitosamente";
	} catch {
		return $_;
	};
}


sub search_ticket {
	my ( $self, $ticket, %datos ) = @_;
		
	my $rt = $self->auth( $datos{user}, $datos{pass} );

	try {
		my $resultado = RT::Client::REST::Ticket->new( rt => $rt, id => $ticket )->retrieve;
		return $resultado;
	}catch {
		return $_; 
	}

}

sub asignar {
	my ( $self, $ticket, %datos ) = @_;

	my $rt = $self->auth( $datos{user}, $datos{pass} );

	try {
	my $ticket =  RT::Client::REST::Ticket->new(
                                                 rt => $rt,
                                                 subject => "",
                                                 queue => 'correspondencia_entrante',
                                                 owner => $datos{user},
                                                 cf => {
	                                                      instruccion       =>  "joel",
                                                        },
                                                 )->store();
	
#	$rt->link_tickets( src => $padre, dst => $ticket->id, link_type => 'DependsOn');
	return 1;
	}catch {
		return $_; 
	}

}

sub query {
	my ( $self, %datos ) = @_;

	my $rt = $self->auth( $datos{user}, $datos{pass} );

	try {
		my @ids = $rt->search(
		    					type => 'ticket',
						    	query => $datos{query},
					         );

		my $search = RT::Client::REST::SearchResult->new(
                                                         ids => \@ids,
                                                         object => sub {
                                                         RT::Client::REST::Ticket->new(
                                                                                        id => shift,
                                                                                        rt => $rt,
                                                                                       ),
                                                                        },
                                                         );
		my $iterator = $search->get_iterator;
		my $lista;

		while (defined(my $obj = &$iterator) ) {
               push @$lista, {
                            id     =>  $obj->id,
                            asunto =>  encode("utf-8",$obj->subject),
							remitente => encode("utf-8", $obj->cf('remitente')),
							organismo => encode("utf-8", $obj->cf('organismo')),
							destinatario => encode("utf-8", $obj->cf('destinatario')),
							respuesta => encode("utf-8", $obj->cf('respuesta')),
							fecha_respuesta => fecha_usuario($obj->cf('fecha_respuesta')),
							tipo => encode("utf-8", $obj->cf('tipo')),
							fecha_creacion => fecha_usuario( $obj->cf('fecha_recepcion') ),
							cargado 	=> uc($obj->cf('cargado')),
							observaciones => $obj->cf('observaciones'),
							anexo => $obj->cf('anexo'),
							cola  => $obj->queue,
							}
		}
	
		return \@$lista;
	}catch {
		return $_;
	}
}

sub download {
	my ( $self, %datos ) = @_;
	
	my $rt = $self->auth( $datos{user}, $datos{pass} );
	my $ticket; 

	try {
		$ticket = RT::Client::REST::Ticket->new( rt => $rt, id => $datos{arg} )->retrieve;
		return $ticket;
	}catch {
		return $_; 
	}

}

=head1 NAME

CorrespondenciaCorpoelec::Model::RT - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Joel Enrique Gomez Brito

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
