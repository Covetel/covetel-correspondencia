package CorrespondenciaCorpoelec::Controller::Correspondencia;
use Moose;
use namespace::autoclean;
use File::Copy;
use Validaciones::Librerias qw( fecha_usuario usuario_fecha upload_attachment);

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head1 NAME

CorrespondenciaCorpoelec::Controller::Correspondencia - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

#    $c->response->body('Matched CorrespondenciaCorpoelec::Controller::Correspondencia in Correspondencia.');
}

sub recepcion : Local : FormConfig {
	my ( $self, $c ) = @_;
	
	$c->stash->{template} = "correspondencia/recepcion.tt2";
	$c->flash->{usuario} = $c->session->{user};
	my $form = $c->stash->{form};
    $form->auto_constraint_class( 'constraint_%t' );

}

sub recepcion_FORM_VALID : Local {
	my ( $self, $c ) = @_;


	my $form = $c->stash->{form};
	
	my $destinatario = ( $form->param_value('otro') and $form->param_value('destinatario') == "Otro" ) ? $form->param_value('otro') : $form->param_value('destinatario');
	my %datos = (
					asunto			=>  $form->param_value('asunto'),
					remitente		=>  $form->param_value('remitente'),
					organismo 		=>  $form->param_value('organismo'),
					fecha_recepcion =>  $form->param_value('fecha_recepcion'),
					prioridad		=>  $form->param_value('prioridad'),
					anexos 			=>  $form->param_value('anexos'),
					obs 			=>  $form->param_value('obs'),
					destinatario    =>  $destinatario,
					tipo			=>  $form->param_value('tipo'),
					respuesta		=>  $form->param_value('respuesta'),
					fecha_respuesta =>  $form->param_value('fecha_respuesta'),
					remitido		=>  $form->param_value('remitido'),
					cargo_remitente =>  $form->param_value('cargo_remitente'),
					adjunto			=>  $form->param('adjunto'),
					user			=>  $c->session->{user},
					pass			=>  $c->session->{pass},
					cola			=>  "correspondencia_entrante"
				);

	my $resp = $c->model("RT")->save_correspondencia( %datos );

	if ( ref($resp) =~ /RT::Client::REST/ ) {
		$c->flash->{error_msg} = $resp;
	}else{
		$c->flash->{status_msg} = $resp;
	}
	$c->response->redirect( $c->uri_for("/correspondencia/recepcion") );
}

sub envio : Local : FormConfig {
	my ( $self, $c ) = @_;
	
	$c->stash->{template} = "correspondencia/envio.tt2";
	$c->flash->{usuario} = $c->session->{user};
	my $form = $c->stash->{form};
    $form->auto_constraint_class( 'constraint_%t' );

}

sub envio_FORM_VALID : Local {
	my ( $self, $c ) = @_;


my $form = $c->stash->{form};

	my %datos = (
			asunto		=>  $form->param_value('asunto'),
			remitente	=>  $form->param_value('remitente'),
			cargo_remitente	=>  $form->param_value('cargo_remitente'),
			numero_doc 	=>  $form->param_value('numero_doc'),
			destinatario	=>  $form->param_value('destinatario'),
			cargo_destinatario 	=>  $form->param_value('cargo_destinatario'),
			fecha_envio	=>  $form->param_value('fecha_envio'),
			resumen		=>  $form->param_value('resumen'),
			prioridad	=>  "1",,
			adjunto		=>  $form->param('adjunto'),
			user		=>  $c->session->{user},
			pass		=>  $c->session->{pass},
			cola		=>  "correspondencia_saliente"
 		    );

	my $resp = $c->model("RT")->save_envio( %datos );

	if ( ref($resp) =~ /RT::Client::REST/ ) {
		$c->flash->{error_msg} = $resp;
	}else{
		$c->flash->{status_msg} = $resp;
	}
	$c->response->redirect( $c->uri_for("/correspondencia/envio") );

}

sub etiqueta : Local {
	my ( $self, $c, $arg ) = @_;

	my %datos =(
				user => $c->session->{user},
				pass => $c->session->{pass},
			  );

	my $ticket = $c->model("RT")->search_ticket( $arg, %datos );

	$c->stash(
				ticket => $ticket,
				template => "correspondencia/etiqueta.tt2",
				
			 );
}

sub direccionamiento : Local : FormConfig {
	my ( $self, $c ) = @_;

	my $form = $c->stash->{form};
	$c->stash->{template} = "correspondencia/direccionamiento.tt2";
}

sub buscar_correlativo : Local {
	my ( $self, $c ) = @_;

	my $arg = $c->request->param('correlativo');
	my %datos =(
				user => $c->session->{user},
				pass => $c->session->{pass},
			  );

	my $ticket = $c->model("RT")->search_ticket( $arg, %datos );

	if ( ref($ticket) =~ /RT::Client::REST::Ticket/ ) {
    	
		my $transactions = $ticket->transactions;
        my $str_href= "";
        my $filename;
        my $filetype;
		my $iterator;

        my $attachments = $ticket->attachments;
        my $count = $attachments->count;
        $iterator = $attachments->get_iterator;

        while (my $att = &$iterator) {
             if ($att->file_name){
                 $str_href    =  "/correspondencia/descarga/".$att->parent_id;
                 $filename    =  $att->file_name;
                 $filetype    = $att->content_type;
             }
       }
		my %correspondencia = (
								id        => $ticket->id,
								asunto 	  => $ticket->subject,
								remitente => $ticket->cf('remitente'),
								organismo => $ticket->cf('organismo'),
								recibida  => $ticket->owner,
								tipo	  => $ticket->cf('tipo'),
								anexo	  => $ticket->cf('anexo'),
								fecha_recepcion => fecha_usuario($ticket->cf('fecha_recepcion')),
								cola	 => $ticket->queue,
								adjunto         => $filename,
								href            => $str_href
								);	



		$c->stash->{json} = \%correspondencia;
	}elsif ( ref($ticket) =~ /RT::Client::REST::Object::InvalidValueException/ ) {
		$c->stash->{json} = "Session Expirada";

	}else{
		$c->stash->{json} = "Correspondencia no encontrada";

	}

	$c->stash->{current_view} = "JSON";
}

sub buscar_asunto : Local {
	my ( $self, $c ) = @_;

	my $arg = $c->request->param('q');
	my %datos = (
				 user => $c->session->{user},
				 pass => $c->session->{pass},
				 query => "(Queue = 'correspondencia_entrante' or Queue = 'correspondencia_saliente') and Subject like '%$arg%'"
			    );

	my $ticket = $c->model("RT")->query( %datos );
	use Data::Dumper;
	print(Dumper($ticket));
	$c->stash->{json} = $ticket;
	$c->stash->{current_view} = "JSON";

}	

sub buscar_fechas : Local {
	my ( $self, $c ) = @_;

	my $fecha_inicial = usuario_fecha( $c->request->param('fecha_inicial') );
	my $fecha_final   = usuario_fecha( $c->request->param('fecha_final') );

	my %datos = (
				 user => $c->session->{user},
				 pass => $c->session->{pass},
				 query => "(Queue = 'correspondencia_entrante' or Queue = 'correspondencia_saliente') and (CF.fecha_recepcion >= '$fecha_inicial' and CF.fecha_recepcion <= '$fecha_final')"
			    );

	my $ticket = $c->model("RT")->query( %datos );
	$c->stash->{json} = $ticket;
	$c->stash->{current_view} = "JSON";

}
sub retiqueta : Local : FormConfig {
	my ( $self, $c ) = @_;

	my $form = $c->stash->{form};
	$c->flash->{usuario} = $c->session->{user};
        $form->auto_constraint_class( 'constraint_%t' );

}	

sub adjuntar : Local : FormConfig {
	my ( $self, $c ) = @_;

	my $form = $c->stash->{form};
	$c->flash->{usuario} = $c->session->{user};
        $form->auto_constraint_class( 'constraint_%t' );
}

sub  adjuntar_FORM_VALID : Local {
	my ( $self, $c ) = @_;

	my $form = $c->stash->{form};
	
	my $arg = $form->param_value('correlativo');
	my $upload = $form->param_value('adjunto');


	my %datos =( user => $c->session->{user}, pass => $c->session->{pass} );
	my $ticket = $c->model("RT")->search_ticket( $arg, %datos );

	if ( ref($ticket) =~ /RT::Client::REST::Ticket/ ) {
    	
	        my $dir =  $upload->tempname . ".dir$$";
       		my $n   =  "$dir/" . $upload->filename;
	        mkdir $dir;

	        my $fh = $upload->fh;
        	copy($fh, $n);
	        $ticket->comment( message => "esto es un mensaje" , attachments=>[$n] );
    		unlink $n;
	        rmdir $dir;
		$c->flash->{status_msg} = "Correspondencia Adjuntada";

	}elsif ( ref($ticket) =~ /RT::Client::REST::Object::InvalidValueException/ ) {
		$c->flash->{error_msg} = "Session Expirada";

	}else{
		$c->flash->{error_msg} = "Correspondencia no encontrada";

	}
}

sub descarga : Local {
    my ($self, $c, $arg) = @_;

    my $rt = $c->session->{rt};

	my %datos =(
				user => $c->session->{user},
				pass => $c->session->{pass},
				arg  => $arg
			  );

     my $ticket = $c->model("RT")->download( %datos );

     my $attachments = $ticket->attachments;
     my $iterator = $attachments->get_iterator;

     while (my $att = &$iterator) {
                if ($att->file_name){

                        open(F, "/tmp/joel");
                                print F "$att->content";
                        close(F);
                        system();
      my $filename = $att->file_name;
            $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
            $c->res->content_encoding($att->content_encoding);
            $c->res->content_type($att->content_type);
            $c->response->body($att->content);
         }
     }
}

sub reportes : Local : FormConfig {
	my ( $self, $c ) = @_;

	my $form = $c->stash->{form};
	$c->flash->{usuario} = $c->session->{user};
	$c->stash->{tempalte} = "correspondencia/resportes.tt2";
}

sub reporte_diario : Local {
	my ( $self, $c, $dia, $mes, $anio ) = @_;
	
	my $fecha = $anio . "-" . $mes . "-" . $dia;
	my %datos = (
					user => $c->session->{user},
					pass => $c->session->{pass},
					query => "(Queue = 'correspondencia_entrante' or Queue = 'correspondencia_saliente')  and cf.fecha_recepcion = '$fecha'"
				);

	my $resultado = $c->model("RT")->query(%datos);
	
	if ( ref( $resultado ) =~ /ARRAY/ ){
		if ( $$resultado[0]->{id} ) {
			$c->stash->{ resultado } = $resultado;
			$c->stash->{ fecha } = fecha_usuario( $fecha );
			$c->stash->{ pdf_filename } =  "reporte-$dia-$mes-$anio.pdf";
		    $c->stash->{ no_title } = 1;
			$c->stash->{ landscape } = 1;
			$c->stash->{ template } = 'correspondencia/reporte_diario.tt2';
    		$c->stash->{'current_view'} = 'PDF';
		}else{
			$c->stash->{template} = "correspondencia/reportes.tt2";
			$c->response->redirect($c->uri_for('/correspondencia/reportes'));
			$c->flash->{error_msg} = "No hay correspondencias para el d&iacute;a seleccionado";
		}
	}else{
		$c->response->redirect( $c->uri_for('/') );
	}
}

sub reporte_fechas : Local {
	my ( $self, $c, $dia, $mes, $anio, $dia1, $mes1, $anio1  ) = @_;
	
	my $fecha_inicio = $anio . "-" . $mes . "-" . $dia;
	my $fecha_fin    = $anio1 . "-" . $mes1 . "-" . $dia1;
	my %datos = (
				user => $c->session->{user},
				pass => $c->session->{pass},
				query => "(Queue = 'correspondencia_entrante' or Queue = 'correspondencia_saliente') and (cf.fecha_recepcion >= '$fecha_inicio' and cf.fecha_recepcion <= '$fecha_fin')"
				);

	my $resultado = $c->model("RT")->query(%datos);
	
	if ( ref( $resultado ) =~ /ARRAY/ ){
		if ( $$resultado[0]->{id} ) {
			$c->stash->{ resultado } = $resultado;
			$c->stash->{ fecha_inicio } = fecha_usuario( $fecha_inicio );
			$c->stash->{ fecha_fin } = fecha_usuario( $fecha_fin );
			$c->stash->{ pdf_filename } =  "reporte-$dia-$mes-$anio-al-$dia1-$mes1-$anio1.pdf";
	    		$c->stash->{ no_title } = 1;
			$c->stash->{ landscape } = 1;
			$c->stash->{ template } = 'correspondencia/reporte_fechas.tt2';
	    	$c->stash->{'current_view'} = 'PDF';
		}else{
			$c->stash->{template} = "correspondencia/reportes.tt2";
			$c->response->redirect($c->uri_for('/correspondencia/reportes'));
			$c->flash->{error_msg} = "No hay correspondencias en las fechas seleccionadas";
		}
	}else{
		$c->response->redirect( $c->uri_for('/') );
	}

}

sub buscar : Local : FormConfig {
	my ( $self, $c ) = @_;

	$c->flash->{usuario} = $c->session->{user};
	$c->stash->{template} = "correspondencia/buscar.tt2";
	
}

=head1 AUTHOR

Joel Enrique Gomez Brito

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
