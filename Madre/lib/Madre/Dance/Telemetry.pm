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

post '/ping' => sub {
   
};

1;
