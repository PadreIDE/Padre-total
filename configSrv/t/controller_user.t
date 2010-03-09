use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'configSrv' }
BEGIN { use_ok 'configSrv::Controller::user' }

ok( request('/user')->is_success, 'Request should succeed' );
done_testing();
