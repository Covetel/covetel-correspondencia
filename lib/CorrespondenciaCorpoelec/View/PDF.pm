package CorrespondenciaCorpoelec::View::PDF;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

=head1 NAME

CorrespondenciaCorpoelec::View::PDF - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Joel Enrique Gomez Brito

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


use HTML::HTMLDoc;
use Encode;

__PACKAGE__->config->{template_extension} = '.tt2';
__PACKAGE__->config->{page_size} = 'letter';
__PACKAGE__->config->{font_size} = '8';
__PACKAGE__->config->{header} = ['.', '.', '.'];
__PACKAGE__->config->{footer} = ['1', '.', '.'];

sub process {
  my ( $self, $c ) = @_;

  my $template = $c->stash->{template}
    ||  $c->action . $self->config->{template_extension};

  unless (defined $template) {
    $c->log->debug('No template specified for rendering') if $c->debug;
    return 0;
  }

  $c->stash->{ wrapper } = 'pdf';
  my $output = $c->view('TT')->render($c, $template);

  if (UNIVERSAL::isa($output, 'Template::Exception')) {
    my $error = qq/Couldn't render template "$output"/;
    $c->log->error($error);
    $c->error($error);
    return 0;
  }

  my $doc = HTML::HTMLDoc->new( 'mode' => 'file', 'tmpdir' => '/tmp' );
  $doc->set_page_size($self->config->{page_size});
  $doc->set_header(@{$self->config->{header}});
  $doc->set_footer(@{$self->config->{footer}});
  $doc->set_fontsize( $c->stash->{ font_size } || $self->config->{font_size} );
  $doc->no_title() if ( $c->stash->{ no_title } );
  $doc->landscape() if ( $c->stash->{ landscape } );
  $doc->set_top_margin( @{ $c->stash->{top_margin} } ) if ( $c->stash->{top_margin} );
  $doc->set_left_margin( @{ $c->stash->{left_margin} } ) if ( $c->stash->{left_margin} );

  $doc->set_html_content($output);
  my $pdf = $doc->generate_pdf();

  $c->response->content_type('application/pdf; charset=utf-8');
  my $cont_pdf = $pdf->to_string();
  $c->res->header( 'Content-Disposition' => 'attachment;filename='.$c->stash->{pdf_filename} );
  $c->response->content_length( length(Encode::encode_utf8($cont_pdf) ) );
  $c->response->body($cont_pdf);

  return 1;
}

# __PACKAGE__->meta->make_immutable;

1;
