use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Madre::Sync' }
BEGIN { use_ok 'Madre::Sync::Controller::config' }

ok( request('/config')->is_success, 'Request should succeed' );
done_testing();
