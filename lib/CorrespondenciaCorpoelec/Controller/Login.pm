package CorrespondenciaCorpoelec::Controller::Login;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head1 NAME

CorrespondenciaCorpoelec::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0): FormConfig {
    my ( $self, $c ) = @_;

#    $c->response->body('Matched CorrespondenciaCorpoelec::Controller::Login in Login.');
 	$c->stash->{template} = 'login/login.tt2';
	my $form = $c->stash->{form};

}

sub index_FORM_VALID : Local {
	my ( $self, $c ) = @_;

	 my $form = $c->stash->{form};
     my $user = $form->param_value('usuario');
     my $pass = $form->param_value('clave');
         
     my $rt = $c->model('RT')->auth($user, $pass); 
         
     if ( ref($rt) =~ /RT::Client::REST/ ){
		  $c->session->{user} = $user;
		  $c->session->{pass} = $pass;
          $c->flash->{usuario} = $user;
          $c->response->redirect( $c->uri_for('/correspondencia/recepcion') );
      }else{
          $c->flash->{error_msg} = $rt;
          $c->response->redirect( $c->uri_for('/login') );
      }
 }

sub logout : Local {
	my ( $self, $c ) = @_;

	$c->delete_session();
	$c->response->redirect( $c->uri_for('/') );	
}

=head1 AUTHOR

Joel Enrique Gomez Brito

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
