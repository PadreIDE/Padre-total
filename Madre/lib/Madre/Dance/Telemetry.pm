package Madre::Dance::Telemetry;

use 5.008;
use strict;
use JSON                       ();
use DateTime                   ();
use DateTime::Format::Strptime ();
use Try::Tiny;
use Madre::DB;
use Dancer;

our $VERSION = '0.1';





######################################################################
# Receive Uploads

put '/ping/*' => sub {
    my ($padre, $instance_id) = splat;
    unless ( defined $padre and defined $instance_id ) {
        status 500; # Internal error
        return {
            error => "Missing or invalid Padre version or instance",
            title => 'Popularity Contest',
        };
    }

    # Insert or replace existing instance
    Padre::DB::Instance->delete(
        'WHERE instance_id = ?', $instance_id,
    );
    Padre::DB::Instance->create(
        instance_id => $instance_id,
        padre       => $padre,
        data        => param->{data},
    );

    status 204;
};

1;
