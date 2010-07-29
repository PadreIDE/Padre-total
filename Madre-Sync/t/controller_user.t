use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Madre::Sync' }
BEGIN { use_ok 'Madre::Sync::Controller::user' }

ok( request('/user')->is_success, 'Request should succeed' );
done_testing();
