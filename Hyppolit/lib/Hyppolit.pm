package Hyppolit;
use strict;
use warnings FATAL => 'all';
use 5.008005;

# TODO
# initial welcome message to any new user
# logging
# accept some commands:
#   trust nick   DONE
#     only allow trusting nick that is currently logged in?
#     allow setting trust for anyone with +o ? (or as it is now only already trusted nicks?)
#   karma nick
#   nick++
#   nick--
# daemonize it
# svn commit messages
# trac changes messages
# pastebot integration
# word is explanation
# word is also explanation
# word?
# TODO: keep history?

# When it gets OP bit it should go over all the current nicks and add ops to the trusted people
# oh actually I think it can just rty to add ops to every trusted person and it will give only to those who
# have no OP yet
# Also check that it can give op when someone changs alias to a trusted one



our $VERSION = '0.08';

use base 'Exporter';

use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::IRC::Plugin::Logger;
use POE::Component::IRC::Plugin::FollowTail;
use DBI;

use Data::Dumper;

use YAML::Syck qw(LoadFile DumpFile);
my $svnlook = '/usr/bin/svnlook';

my @methods = qw(
	_start irc_join irc_public irc_msg
	irc_tail_input irc_tail_error irc_tail_reset
	trac_check
);
our @EXPORT = @methods;
my $config;
my $config_file;

sub save_config {
	DumpFile( $config_file, $config );
}

sub run {
	my $class = shift;
	$config_file = shift;

	die "Missing channels. Usage $0 config_file.yml\n" if not $config_file;
	$config = LoadFile($config_file);

	die "No server defined\n" if not $config->{server};
	die "No nick defined\n"   if not $config->{nick};

	if (   not $config->{channels}
		or not ref $config->{channels}
		or ref( $config->{channels} ) ne 'ARRAY'
		or not @{ $config->{channels} } )
	{
		die "No channels defined\n";
	}

	print Dumper $config;

	POE::Session->create( package_states => [ main => \@methods ] );

	$poe_kernel->run();
}

# so that it is accessable outside of the PoCo::IRC
my $irc;
my $dbh;

sub _start {
	$irc = POE::Component::IRC::State->spawn(
		Nick   => $config->{nick},
		Server => $config->{server},
	);

	# TODO: AutoJoin does not seem to rejoin after it was kicked out.

	$irc->plugin_add(
		'AutoJoin',
		POE::Component::IRC::Plugin::AutoJoin->new(
			Channels => $config->{channels},
		)
	);
	if ( $config->{logdir} ) {
		$irc->plugin_add(
			'Logger',
			POE::Component::IRC::Plugin::Logger->new(
				Path    => $config->{logdir},
				Private => 0,
				Public  => 1,

				# Restricted => 0,   #did not help
				Sort_by_date => 1,
			)
		);
		system "chmod -R 755 $config->{logdir}"; # TODO move to a better place
	}
	if ( $config->{inputfile} ) {
		$irc->plugin_add(
			'FollowTail' => POE::Component::IRC::Plugin::FollowTail->new(
				filename => $config->{inputfile},
			)
		);
	}

	$irc->yield( register => 'join' );

	#$irc->yield(register => 'all');
	$irc->yield('connect');

	if ( $config->{tracdb} ) {
		$dbh = DBI->connect( "dbi:SQLite:dbname=" . $config->{tracdb}, "", "" );
		$_[KERNEL]->delay( trac_check => 5 );
	}

}

sub irc_public {
	my $nick = ( split /!/, $_[ARG0] )[0];
	my $channel = $_[ARG1];

	# now unnecessary
	#	my $irc = $_[SENDER]->get_heap();

	my $text = $_[ARG2];

	#print "Nick $nick on channel @$channel said the following: '$text'\n";
	if ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* trust  \s+  (.*)/x ) {

		#print "trust '$1'\n";
		if ( $config->{trusted}{$nick} ) {
			foreach my $n ( split /\s*[ ,]\s*/, $1 ) {
				if ( $config->{trusted}{$n} ) {
					$irc->yield( privmsg => $channel, "$n was already trusted" );
				} else {
					$config->{trusted}{$n} = 1;
					$irc->yield( privmsg => $channel, "Consider $n trusted" );
				}
				set_op( $irc, $channel, $n );
			}
			save_config();
		}
	}

	if ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* (\S+)  \s+ is \s+ also \s+ (.*)/x ) {
		my $word = $1;
		$config->{is}{$word} .= " and also $2";
		save_config();
		$irc->yield( privmsg => $channel, "$word is now $config->{is}{$word}" );
	} elsif ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* (\S+)  \s+ is \s+ (.*)/x ) {
		my $word = $1;
		my $was = $config->{is}{$word} || 'unknown';
		$config->{is}{$word} = $2;
		save_config();
		$irc->yield( privmsg => $channel, "$word was $was" );
		$irc->yield( privmsg => $channel, "$word is now $config->{is}{$word}" );
	} elsif ( $text =~ /^\s*  (\S+)\?  \s*$/x ) {
		if ( $1 eq $config->{nick} ) {
			$irc->yield( privmsg => $channel, "$config->{nick} is a bot currently running version $VERSION" );
			$irc->yield( privmsg => $channel, "My master is szabgab." );
		} elsif ( $config->{is}{$1} ) {
			$irc->yield( privmsg => $channel, "$1 is $config->{is}{$1}" );
		} else {

			#$irc->yield(privmsg => $channel, "I don't know what $1 is");
		}
	} elsif ( $text =~ /^\s*op\s*me\s*$/ ) {
		if ( $config->{trusted}{$nick} ) {
			set_op( $irc, $channel, $nick );
		} else {
			$irc->yield( privmsg => $channel, "Sorry, user '$nick' is not in the list of trusted users" );
		}
	}

	if ( $config->{explain} ) {
		if ( $text =~ /^$config->{explain}:\s*(.*)/ ) {
			my $code = $1;
			require Code::Explain;
			if ( not $code ) {
				$irc->yield(
					privmsg => $channel,
					"You need to type in a perl5 expression and hope that Code::Explain v$Code::Explain::VERSION understand it"
				);
			} else {
				my $ce = Code::Explain->new( code => $code );
				$irc->yield( privmsg => $channel, $ce->explain );
			}
		}
	}

	# regexp need adjusting, i'm bad at it ;)...
	if ( $text =~ /\#(\d+)/x ) {
		if ( $1 + 0 > 0 ) {
			my $text = trac_ticket_text($1);
			$irc->yield( privmsg => $channel, $text ) if $text;
		}
	}

	# regexp need adjusting, i'm bad at it ;)...
	if ( $text =~ /r(\d+)/x ) {

		# no check at all... TODO
		$irc->yield( privmsg => $channel, trac_changeset_text($1) ) if $1 + 0 > 0;
	}

	# TODO karma only users who are around ?
	# record karma
	if ( $text =~ /(\S+)(\+\+|--)/ ) {
		my ( $nick, $karma ) = ( $1, $2 );
		if ( $karma eq '++' ) {
			$config->{karma}{$nick}++;
		} else {
			$config->{karma}{$nick}--;
		}
		save_config();
	}
	if ( $text =~ /^\s* karma \s+ (\S+) \s*$/x ) {
		my $karma = $config->{karma}{$1} || 0;
		$irc->yield( privmsg => $channel, "Karma of $1 is $karma" );
	}
}


sub irc_msg {
	my $nick = ( split /!/, $_[ARG0] )[0];

	#my $channel = $_[ARG1];
	# now unnecessary
	#	my $irc = $_[SENDER]->get_heap();

	my $text = $_[ARG2];

	#print "Nick $nick said to me '$text'\n";
}

sub irc_join {
	my $nick = ( split /!/, $_[ARG0] )[0];
	my $channel = $_[ARG1];

	# now unnecessary
	#	my $irc = $_[SENDER]->get_heap();

	# only send the message if we were the one joining
	if ( $nick eq $irc->nick_name() ) {

		#$irc->yield(privmsg => $channel, "Hi everybody! I am the local bot ($VERSION)");
	}

	# TODO for now it is on every channel
	# but it should work with some database

	if ( $config->{trusted}{$nick} ) {
		set_op( $irc, $channel, $nick );
	}
}

sub set_op {
	my ( $irc, $channel, $nick ) = @_;
	if ( ref $channel and ref($channel) eq 'ARRAY' ) {
		($channel) = @$channel;
	}
	print "Giving op to '$nick' on '$channel' ($irc)\n";
	$irc->yield( mode => $channel => "+o $nick" );

	# its already at another place, should be removed here?
	#	system "chmod -R 755 $config->{logdir}"; # TODO move to a better place
}

sub _default {
	my $nick = ( split /!/, $_[ARG0] )[0];
	print "Default: $nick ", scalar(@_), "\n";
}

sub irc_all {
	my $nick = ( split /!/, $_[ARG0] )[0];
	print "All: $nick ", scalar(@_), "\n";
}


sub irc_tail_input {
	my ( $kernel, $sender, $filename, $input ) = @_[ KERNEL, SENDER, ARG0, ARG1 ];
	my $repo = $config->{repo};
	return if not $repo;
	if ( $input =~ /^SVN (\d+)$/ ) {
		my $id     = $1;
		my $author = qx{$svnlook author $repo -r $id};
		chomp $author;
		$config->{karma}{$author}++;
		my $log  = qx{$svnlook log $repo -r $id};
		my @dirs = qx{$svnlook dirs-changed $repo -r $id};
		chomp @dirs;
		my $msg = "svn: r$id | $author++ | http://padre.perlide.org/trac/changeset/$id\n";
		$kernel->post( $sender, 'privmsg', $_, $msg ) for @{ $config->{channels} };

		foreach my $line ( split /\n/, $log ) {
			$kernel->post( $sender, 'privmsg', $_, "     $line" ) for @{ $config->{channels} };
		}
		my $dirs = join " ", @dirs;
		$kernel->post( $sender, 'privmsg', $_, "     $dirs" ) for @{ $config->{channels} };

	}

	# TODO report error ?
	# $kernel->post( $sender, 'privmsg', $_, "$config->{inputfile} $input" ) for @{ $config->{channels} };
	return;
}

sub irc_tail_error {
	my ( $kernel, $sender, $filename, $errnum, $errstring ) = @_[ KERNEL, SENDER, ARG0 .. ARG2 ];
	$kernel->post( $sender, 'privmsg', $_, "SVN ERROR: $errnum $errstring" ) for @{ $config->{channels} };

	# now unnecessary
	#	my $irc = $sender->get_heap();
	$irc->plugin_del('FollowTail');
	return;
}

sub irc_tail_reset {
	my ( $kernel, $sender, $filename ) = @_[ KERNEL, SENDER, ARG0 ];

	#	$kernel->post( $sender, 'privmsg', $_, "$config->{inputfile} RESET EVENT" ) for @{ $config->{channels} };
	return;
}

sub trac_changeset_text {
	my $changeset_id = shift;
	return "Changeset #" . $changeset_id . " http://padre.perlide.org/trac/changeset/" . $changeset_id;
}

sub trac_ticket_text {
	my $ticket_id = shift;
	my $type      = shift;

	return if !$config->{tracdb};

	my $ticket = $dbh->selectrow_hashref(
		q{
		SELECT *
                FROM ticket
		WHERE id = ?
	        }, {}, $ticket_id
	);
	return if !$ticket;
	my $ticket_comment = $dbh->selectrow_hashref(
		q{
		SELECT oldvalue, author
                FROM ticket_change
		WHERE ticket = ?
                  AND field = 'comment'
		  ORDER BY time DESC
	        }, {}, $ticket_id
	);
	my $url = "http://padre.perlide.org/trac/ticket/" . $ticket_id;

	my $msg = "# $ticket_id :  $ticket->{summary} ($ticket->{status} $ticket->{type}) of $ticket->{owner}";

	if ($ticket_comment) {
		if ( $ticket_comment->{oldvalue} ) {
			$url .= "#comment:" . $ticket_comment->{oldvalue};
		}
		if ( $ticket_comment->{author} ) {
			$msg .= " by $ticket_comment->{author} ";
		}
	}
	if ($type) {
		if ( $type eq 'attachment' ) {
			$msg .= " new attachment";
		}
	}
	$msg .= " [ $url ]";

	return $msg;

}

sub trac_check {
	my $trac_check_time = time;
	my $last_trac_check = $config->{last_trac_check};

	# Starting from v0.12 Trac keeps the changetime in
	# microsecond so we need adjust
	my $microseconds = 1_000_000;

	my %tickets;
	$tickets{change} = $dbh->selectall_hashref(
		q{
		SELECT id
                FROM ticket
		WHERE 
                   changetime > ?
                   AND changetime <= ?
		   ORDER BY changetime ASC
	}, "id", {}, $last_trac_check * $microseconds, $trac_check_time * $microseconds
	);

	$tickets{attachment} = $dbh->selectall_hashref(
		q{
	       SELECT id FROM attachment
	       WHERE
                   type = 'ticket'
                   AND changetime > ?
                   AND changetime <= ?
	       ORDER BY time ASC
	}, "id", {}, $last_trac_check * $microseconds, $trac_check_time * $microseconds
	);

	for my $type (qw(change attachment)) {
		for my $ticket_id ( keys %{ $tickets{$type} } ) {
			my $text = trac_ticket_text( $ticket_id, $type );
			if ($text) {
				$irc->yield( privmsg => $_, $text ) for @{ $config->{channels} };
			}
		}
	}

	$config->{last_trac_check} = $trac_check_time;
	save_config;
	$_[KERNEL]->delay( trac_check => 30 );
	return;
}

1;


