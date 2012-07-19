package Hyppolit;

use strict;
use warnings FATAL => 'all';

# use 5.008005;
use v5.10;

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

my $trac_channel = '#padre';
my $trac_timeout = 5;

our $VERSION = '0.16';

use base 'Exporter';

use POE qw( 
	Component::IRC 
	Component::IRC::State 
	Component::IRC::Plugin::AutoJoin
	Component::IRC::Plugin::Logger
	Component::IRC::Plugin::FollowTail
	);

# use POE;
# use POE::Component::IRC::State;
# use POE::Component::IRC::Plugin::AutoJoin;
# use POE::Component::IRC::Plugin::Logger;
# use POE::Component::IRC::Plugin::FollowTail;

use IRC::Utils qw( GREEN LIGHT_CYAN ORANGE YELLOW NORMAL );
use DBI;

# use Data::Dumper;
use Data::Printer {
	caller_info => 0,
	colored     => 1,
};

# use YAML::Syck qw(LoadFile DumpFile);
use YAML::XS qw(LoadFile DumpFile);
my $svnlook = '/usr/bin/svnlook';

my @methods = qw(
	_start irc_join irc_public irc_msg irc_nick
	irc_tail_input irc_tail_error irc_tail_reset
	trac_check
	enable_registration
	disable_registration
	open
);
our @EXPORT = @methods;

my $config;
my $config_file;

sub save_config {

	# p $config_file;
	# p $config;
	DumpFile( $config_file, $config );
	return;
}

sub run {
	my $class = shift;
	$config_file = shift;

	# p $config_file;

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

	# print Dumper $config;
	p $config;

	POE::Session->create( package_states => [ main => \@methods ], );

	say $config->{nick} . ' is running against ' . $config->{channels}[0] . ' on ' . $config->{server};
	$poe_kernel->run();
	return;
}

# so that it is accessable outside of the PoCo::IRC
my $irc;
my $dbh;

sub _start {
	$irc = POE::Component::IRC::State->spawn(
		Nick   => $config->{nick},
		Server => $config->{server},
	);

	# TODO: AutoJoin does not seem to rejoin after it was kicked out. dose now 
	$irc->plugin_add(
		'AutoJoin',
		POE::Component::IRC::Plugin::AutoJoin->new(
			Channels => $config->{channels},
			#missing bits follow, bowtie
			RejoinOnKick => 1, #enable rejoin
			Rejoin_delay => 7, #delay a nice little prime (seconds)
		)
	);
    $irc->yield(register => qw(join) );
    $irc->yield(connect => { } );

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

	if ( $config->{tracdb} ) {
		$dbh = DBI->connect( "dbi:SQLite:dbname=" . $config->{tracdb}, "", "" );
		$_[KERNEL]->delay( trac_check => 5 );
	}
	return;
}

sub irc_public {
	my $nick = ( split /!/, $_[ARG0] )[0];
	my $channel = $_[ARG1];

	# now unnecessary
	#	my $irc = $_[SENDER]->get_heap();

	my $text = $_[ARG2];

	# Example:
	# hyppolit: trust nickname
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

	# Example:
	# Hyppolit: word is also text
	if ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* (\S+)  \s+ is \s+ also \s+ (.*)/x ) {
		my $word = $1;
		$config->{is}{$word} .= " and also $2";

		# p $config->{is}{$word};
		save_config();
		$irc->yield( privmsg => $channel, "$word is now $config->{is}{$word}" );

		# Example:
		# Hyppolit: word is text
	} elsif ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* (\S+)  \s+ is \s+ (.*)/x ) {
		my $word = $1;
		my $was = $config->{is}{$word} || 'unknown';
		$config->{is}{$word} = $2;
		save_config();
		$irc->yield( privmsg => $channel, "$word was $was" );
		$irc->yield( privmsg => $channel, "$word is now $config->{is}{$word}" );

		# Example:
		# Hyppolit: trac!
	} elsif ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* trac!/x ) {

		#$irc->yield( privmsg => $channel, "Channel $channel" );
		#$irc->yield( privmsg => $channel, "@$channel" );
		return if not grep { $_ eq $trac_channel } @$channel;
		return if not enable_registration();
		$_[KERNEL]->delay( disable_registration => 60 * $trac_timeout );

	} elsif ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* tell \s+ (\w+) \s+ (.*)/x ) {
		my ( $to, $msg ) = ( $1, $2 );
		push @{ $config->{messages}{$to} },
			{
			who  => $nick,
			what => $msg,
			when => time,
			};
		$irc->yield( privmsg => $channel, "$nick, I'll tell that $to when we see each other." );
		save_config();

		# word?
	} elsif ( $text =~ /^\s*  (\S+)\?  \s*$/x ) {
		my $word = $1;
		if ( $word eq $config->{nick} ) {
			$irc->yield( privmsg => $channel, $config->{nick} . ' is a bot currently running version ' . $VERSION );
			$irc->yield( privmsg => $channel, 'My master is szabgab.' );
		} elsif ( $word eq 'uptime' ) {
			chomp( my $uptime = qx{uptime} );
			$irc->yield( privmsg => $channel, $uptime );
		} elsif ( $config->{is}{$word} ) {
			$irc->yield( privmsg => $channel, "$word is $config->{is}{$word}" );
		} else {

			#$irc->yield(privmsg => $channel, "I don't know what $word is");
		}
	} elsif ( $text =~ /^\s*op\s*me\s*$/ ) {
		if ( $config->{trusted}{$nick} ) {
			set_op( $irc, $channel, $nick );
		} else {
			$irc->yield( privmsg => $channel, "Sorry, user '$nick' is not in the list of trusted users" );
		}
	}

	###
	# exepmental feature using Code::Explain
	###
	if ( $config->{explain} ) {
		if ( $text =~ /^$config->{explain}:\s*(?<code>.*)/sxm ) {
			my $code = $+{code};
			require Code::Explain;
			if ( not $code ) {
				$irc->yield(
					privmsg => $channel,
					ORANGE
						. "INFO: You need to type in a perl5 expression and hope that Code::Explain v$Code::Explain::VERSION understands it."
						. NORMAL
				);
			} else {
				my $ce = Code::Explain->new( code => $code );
				if ( $ce->explain eq 'Not found' ) {
					$irc->yield(
						privmsg => $channel,
						ORANGE
							. "INFO: You need to type in a perl5 expression and hope that Code::Explain v$Code::Explain::VERSION understands it."
							. NORMAL
					);
				} else {
					$irc->yield( privmsg => $channel, GREEN . $ce->explain . NORMAL );
				}
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

	if ( $text =~ /^help/ ) {
		$irc->yield( privmsg => $nick, 'help is on the way ' . $nick );
		if ( $config->{trusted}{$nick} ) {
			$irc->yield( privmsg => $nick, YELLOW . 'op help' . NORMAL );
			$irc->yield(
				privmsg => $nick,
				YELLOW . 'op me'
					. NORMAL
					. ' kick the bot in to re-establishing your IRC '
					. @{$channel}[0]
					. ' op status if trusted'
			);
			$irc->yield(
				privmsg => $nick,
				YELLOW . $config->{nick} . ': trust nickname' . NORMAL . ' make the nickname an op ' . @{$channel}[0]
			);
		}

		$irc->yield( privmsg => $nick, LIGHT_CYAN . @{$channel}[0] . ' user help' . NORMAL );
		$irc->yield( privmsg => $nick, LIGHT_CYAN . 'nickname++' . NORMAL . ' add karma' );
		$irc->yield( privmsg => $nick, LIGHT_CYAN . 'nickname--' . NORMAL . ' remove karma' );
		$irc->yield( privmsg => $nick, LIGHT_CYAN . 'karma nickname' . NORMAL . ' show karma' );
		$irc->yield(
			privmsg => $nick,
			LIGHT_CYAN . $config->{nick} . ': tell nickname message' . NORMAL . ' leave a message for some one who is not currently on irc'
		);
		$irc->yield(
			privmsg => $nick,
			LIGHT_CYAN
				. $config->{nick}
				. ': word is text'
				. NORMAL
				. ' teach '
				. @{$channel}[0]
				. ' about a new word = text'
		);
		$irc->yield(
			privmsg => $nick,
			LIGHT_CYAN
				. $config->{nick}
				. ': word is also text'
				. NORMAL
				. ' teach '
				. @{$channel}[0]
				. ' more about word .= text'
		);
		$irc->yield( privmsg => $nick, LIGHT_CYAN . 'word?' . NORMAL . ' show what we know about word' );
		$irc->yield(
			privmsg => $nick,
			LIGHT_CYAN . $config->{explain} . ': <perl code>' . NORMAL . ' expermental see Code::Explain'
		);
		$irc->yield( privmsg => $nick, LIGHT_CYAN . $config->{nick} . '?' . NORMAL . ' info about me' );
		$irc->yield( privmsg => $nick, LIGHT_CYAN . 'uptime?' . NORMAL . ' see how old I am' );

		$irc->yield( privmsg => $nick, ORANGE . 'IRC help' . NORMAL );
		$irc->yield(
			privmsg => $nick,
			ORANGE . '/HELP' . NORMAL . ' http://www.ircbeginner.com/ircinfo/ircc-commands.html'
		);
		$irc->yield( privmsg => $nick, '__END__' );
	}
	return;
}


sub irc_msg {
	my $nick = ( split /!/, $_[ARG0] )[0];

	#print "Nick $nick said to me '$text'\n";

	#my $channel = $_[ARG1];
	# now unnecessary
	#	my $irc = $_[SENDER]->get_heap();

	my $text = $_[ARG2];
	if ( $text eq 'read' ) {
		if ( $config->{messages}{$nick} ) {
			foreach my $msg ( @{ $config->{messages}{$nick} } ) {
				$irc->yield( privmsg => $nick, "$msg->{who} said $msg->{what}" );
			}
			delete $config->{messages}{$nick};
			save_config();
		} else {
			$irc->yield( privmsg => $nick, "You don't have any messages" );
		}
	}
	return;
}

sub irc_join {
	my $nick = ( split /!/, $_[ARG0] )[0];
	my $channel = $_[ARG1];
	# $irc->yield(privmsg => $channel => "hi $channel!");
	# say ' nick joined : ' . $nick;

	#print "nick joined $nick\n";

	# now unnecessary
	#	my $irc = $_[SENDER]->get_heap();

	# only send the message if we were the one joining
	if ( $nick eq $irc->nick_name() ) {
		$irc->yield(privmsg => $channel, "Hi I am $nick the $channel channel bot (v$VERSION), please op me");
		return;
	}

	# TODO for now it is on every channel
	# but it should work with some database

	if ( $config->{trusted}{$nick} ) {
		set_op( $irc, $channel, $nick );
		$irc->yield( privmsg => $channel, YELLOW . 'Welcome ' . $nick . NORMAL );
	}

	#Advise machine generated nicks to change them
	elsif ( $nick =~ /^(user|mib)_/ ) {
		$irc->yield(
			privmsg => $channel,
			ORANGE . 'INFO: Please change your machine generated nickname ' . $nick . ' for continuity' . NORMAL
		);
		$irc->yield(
			privmsg => $channel,
			'Example: type /nick newnickname( limit 9 characters ) ' . GREEN . ' Thank You' . NORMAL
		);
	} else {
		$irc->yield( privmsg => $channel, LIGHT_CYAN . "Welcome $nick" . NORMAL );
	}

	# check if there were any messages and send private message if there were any
	if ( $config->{messages}{$nick} ) {
		$irc->yield(
			privmsg => $nick,
			'You have ' . @{ $config->{messages}{$nick} } . " messages. Type 'read' to read them."
		);
	}
	return;
}

#######
#
#######
sub irc_nick {
	my $old_nick = ( split /!/, $_[ARG0] )[0];
	my $nick = $_[ARG1];

	###
	#
	#TODO check array againts Padre as this only works for hard coded channel
	#
	####
	my $channel = $config->{channels}[0];
	say 'irc_nick changed : ' . $nick;

	# p $channel;

	#print "nick joined $nick\n";

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
		$irc->yield( privmsg => $channel, YELLOW . 'Welcome ' . $nick . NORMAL );
	}

	#Advise machine generated nicks to change them
	elsif ( $nick =~ /^(user|mib)_/sxm ) {
		$irc->yield(
			privmsg => $channel,
			ORANGE . 'INFO: Please change your machine generated nickname ' . $nick . ' for continuity' . NORMAL
		);
		$irc->yield(
			privmsg => $channel,
			'Example: type /nick newnickname( limit 9 characters ) ' . GREEN . ' Thank You' . NORMAL
		);
	} else {
		$irc->yield( privmsg => $channel, LIGHT_CYAN . 'Welcome ' . $nick . NORMAL );
	}

	# check if there were any messages and send private message if there were any
	if ( $config->{messages}{$nick} ) {
		$irc->yield(
			privmsg => $nick,
			'You have ' . @{ $config->{messages}{$nick} } . " messages. Type 'read' to read them."
		);
	}
	return;
}

sub set_op {
	my ( $irc, $channel, $nick ) = @_;
	if ( ref $channel and ref($channel) eq 'ARRAY' ) {
		($channel) = @$channel;
	}
	say 'Giving op to ' . $nick . ' on ' . $channel; #." ($irc)";
	$irc->yield( mode => $channel => ' +o ' . $nick );

	# its already at another place, should be removed here?
	#	system "chmod -R 755 $config->{logdir}"; # TODO move to a better place
	return;
}

sub _default {
	my $nick = ( split /!/, $_[ARG0] )[0];
	print "Default: $nick ", scalar(@_), "\n";
	return;
}

sub irc_all {
	my $nick = ( split /!/, $_[ARG0] )[0];
	print "All: $nick ", scalar(@_), "\n";
	return;
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

	my $msg = "# $ticket_id :  $ticket->{summary} ($ticket->{status} $ticket->{type})";

	# of $ticket->{owner}";

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
                   AND time > ?
                   AND time <= ?
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

	my $wiki = $dbh->selectall_hashref(
		q{
	         SELECT name, author
                 FROM wiki
                 WHERE
                   time > ?
                   AND time <= ?
                 ORDER BY time ASC
	}, "name", {}, $last_trac_check * $microseconds, $trac_check_time * $microseconds
	);

	for my $page ( keys %$wiki ) {
		my $text = "wiki page http://padre.perlide.org/trac/wiki/$page changed by $wiki->{$page}{author}";
		$irc->yield( privmsg => $_, $text ) for @{ $config->{channels} };
	}


	$config->{last_trac_check} = $trac_check_time;
	save_config;
	$_[KERNEL]->delay( trac_check => 30 );
	return;
}

sub disable_registration {
	eval { trac('disabled'); };
	my $error = $@;
	if ($error) {
		$irc->yield( privmsg => $trac_channel, $error );
		return;
	}
	$irc->yield( privmsg => $trac_channel, 'Trac registration closed ' );
	return 1;
}

sub enable_registration {
	eval { trac('enabled'); };
	my $error = $@;
	if ($error) {
		$irc->yield( privmsg => $trac_channel, $error );
		return;
	}
	$irc->yield(
		privmsg => $trac_channel,
		"Trac registration opened for $trac_timeout minutes. Please visit http://padre.perlide.org/trac/register to register"
	);
	return 1;
}

sub trac {
	my $what = shift;
	my $file = '/var/trac/padre/conf/trac.ini';
	open my $in, '<', $file or die "Could not open '$file' for reading \n ";
	my @content = <$in>;
	close $in;
	@content = map { $_ =~ s/(acct_mgr.web_ui.registrationmodule\s*=\s*)(enabled|disabled)/$1$what/; $_ } @content;
	open my $out, '>', $file or die " Could not open '$file' for writing \n ";
	print $out @content;
	close $out;

	return;
}

1;


