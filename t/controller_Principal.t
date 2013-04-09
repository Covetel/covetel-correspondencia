use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CorrespondenciaCorpoelec';
use CorrespondenciaCorpoelec::Controller::Principal;

ok( request('/principal')->is_success, 'Request should succeed' );
done_testing();
