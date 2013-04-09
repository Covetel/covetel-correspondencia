use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CorrespondenciaCorpoelec';
use CorrespondenciaCorpoelec::Controller::Correspondencia;

ok( request('/correspondencia')->is_success, 'Request should succeed' );
done_testing();
