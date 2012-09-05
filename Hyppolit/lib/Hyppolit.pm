package Hyppolit;

use strict;
use warnings FATAL => 'all';

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

our $VERSION = '0.18';

use base 'Exporter';

use POE qw(
	Component::IRC
	Component::IRC::State
	Component::IRC::Plugin::AutoJoin
	Component::IRC::Plugin::Logger
	Component::IRC::Plugin::FollowTail
);

use IRC::Utils qw( BOLD GREEN LIGHT_CYAN ORANGE YELLOW NORMAL PURPLE RED );
use DBI;

use Data::Printer {
	caller_info => 1,
	colored     => 1,
};

use DateTime;
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
	DumpFile( $config_file, $config );
	return;
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

	p $config;

	POE::Session->create( package_states => [ main => \@methods ], );

	say $config->{nick} . ' is running against ' . $config->{channels}[0] . ' on ' . $config->{server};
	$poe_kernel->run();
	return;
}

# so that it is accessable outside of the PoCo::IRC
my $irc;
my $dbh;

#######
# event handler for _start
#######
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

	$irc->yield( register => qw(join) );
	$irc->yield( connect  => {} );

	if ( $config->{logdir} ) {
		$irc->plugin_add(
			'Logger',
			POE::Component::IRC::Plugin::Logger->new(
				Path             => $config->{logdir},
				Private          => 0,
				Public           => 1,
				Strip_color      => 1,
				Strip_formatting => 1,
				Notices          => 0,
				DCC              => 0,

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

#######
# event handler for public
#######
sub irc_public {
	my $who     = $_[ARG0];
	my $nick    = ( split /!/, $_[ARG0] )[0];
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
					$irc->yield( privmsg => $channel, PURPLE . "$n was already trusted" . NORMAL );
				} else {
					$config->{trusted}{$n} = 1;
					$irc->yield( privmsg => $channel, PURPLE . "Consider $n trusted" . NORMAL );
				}
				set_op( $irc, $channel, $n );
			}
			save_config();
		}
	}

	# Example:
	# hyppolit: hop nickname
	#print "Nick $nick on channel @$channel said the following: '$text'\n";
	if ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* hop  \s+  (?<hop>.*)/x ) {

		say 'trying to hop ' . $+{hop};
		if ( $config->{trusted}{$nick} ) {
			foreach my $n ( split /\s*[ ,]\s*/, $+{hop} ) {
				if ( $config->{halfop}{$n} ) {
					$irc->yield( privmsg => $channel, PURPLE . "$n is already a hop" . NORMAL );
				} else {
					$config->{halfop}{$n} = 1;
					set_hop( $irc, $channel, $n );
					save_config();
					$irc->yield( privmsg => $channel, PURPLE . "Consider $n now a hop" . NORMAL );
				}
			}
		}
	}

	# Example:
	# hyppolit: dehop nickname
	#print "Nick $nick on channel @$channel said the following: '$text'\n";
	if ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* dehop  \s+  (?<hop>.*)/x ) {

		say 'trying to dehop ' . $+{hop};
		if ( $config->{trusted}{$nick} ) {
			foreach my $n ( split /\s*[ ,]\s*/, $+{hop} ) {
				if ( $config->{halfop}{$n} ) {
					$config->{halfop}{$n} = 0;
					set_dehop( $irc, $channel, $n );
					save_config();
					$irc->yield( privmsg => $channel, RED . "Rescinded $n as a hop" . NORMAL );
				}
			}
		}
	}

	# Example:
	# hyppolit: ban nickname
	#print "Nick $nick on channel @$channel said the following: '$text'\n";
	if ( $text =~ /^\s*  $config->{nick} \s* [,:]? \s* ban  \s+  (?<ban>.*)/x ) {

		say 'trying to ban ' . $+{ban};
		if ( $config->{trusted}{$nick} ) {
			foreach my $n ( split /\s*[ ,]\s*/, $+{ban} ) {
				if ( !$config->{trusted}{$n} ) {
					$config->{ban}{$n} = 1;
					set_ban( $irc, $channel, $n );
					save_config();
					$irc->yield( privmsg => $channel, RED . "Consider $n now baned" . NORMAL );
				} else {
					$irc->yield(
						privmsg => $channel,
						PURPLE . "Sorry, banning another trustie dose not compute!" . NORMAL
					);
					say 'We have a problem ' . $nick . ' just tried to ban ' . $n;
				}
			}
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

	if ( $text =~ /^help$/ ) {
		my @help;
		push @help, 'help is on the way ' . $nick;
		if ( $config->{trusted}{$nick} ) {

			# push @help, YELLOW . 'op help' . NORMAL;
			push @help,
				  YELLOW . 'op me'
				. NORMAL
				. ' kick the bot in to re-establishing your IRC '
				. @{$channel}[0]
				. ' op status if trusted';
			push @help,
				YELLOW . $config->{nick} . ': trust nickname' . NORMAL . ' make the nickname an op ' . @{$channel}[0];
			push @help,
				YELLOW . $config->{nick} . ': hop nickname' . NORMAL . ' make the nickname an hop ' . @{$channel}[0];
			push @help,
				  YELLOW
				. $config->{nick}
				. ': dehop nickname'
				. NORMAL
				. ' remove the nickname as a hop '
				. @{$channel}[0];
			push @help,
				  YELLOW
				. $config->{nick}
				. ': ban nickname'
				. NORMAL
				. " ban nick then kick the nick, added to banned list, dose not work against op's "
				. @{$channel}[0];
		}
		push @help, LIGHT_CYAN . @{$channel}[0] . ' channel help' . NORMAL;
		push @help, LIGHT_CYAN . 'nickname++' . NORMAL . ' add karma';
		push @help, LIGHT_CYAN . 'nickname--' . NORMAL . ' remove karma';
		push @help, LIGHT_CYAN . 'karma nickname' . NORMAL . ' show karma';
		push @help,
			  LIGHT_CYAN
			. $config->{nick}
			. ': tell nickname message'
			. NORMAL
			. ' leave a message for some one who is not currently on irc';
		push @help,
			  LIGHT_CYAN
			. $config->{nick}
			. ': word is text'
			. NORMAL
			. ' teach '
			. @{$channel}[0]
			. ' about a new word = text';
		push @help,
			  LIGHT_CYAN
			. $config->{nick}
			. ': word is also text'
			. NORMAL
			. ' teach '
			. @{$channel}[0]
			. ' more about word .= text';
		push @help, LIGHT_CYAN . 'word?' . NORMAL . ' show what we know about word';
		push @help, LIGHT_CYAN . $config->{explain} . ': <perl code>' . NORMAL . ' expermental see Code::Explain';
		push @help, LIGHT_CYAN . $config->{nick} . '?' . NORMAL . ' info about me';
		push @help, LIGHT_CYAN . 'uptime?' . NORMAL . ' see how old I am';
		push @help, ORANGE . 'IRC help' . NORMAL;
		push @help, ORANGE . '/HELP' . NORMAL . ' http://www.ircbeginner.com/ircinfo/ircc-commands.html';
		push @help, '__END__';
		$irc->yield( privmsg => $nick => $_ ) for @help;

	}
	return;
}

#######
# event handler for msg
#######
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

#######
# event handler for join channel
#######
sub irc_join {
	my $nick = ( split /!/, $_[ARG0] )[0];
	my $channel = $_[ARG1];
	
	# Build a date representing Padre birthday
	my $birthday = DateTime->new( year => 2008, month => 7, day => 20, );
	my $dt = DateTime->now;

	if ( $config->{ban}{$nick} ) {
		set_ban( $irc, $channel, $nick );
		return;
	}

	# only send the message if we were the one joining
	if ( $nick eq $irc->nick_name() ) {
		$irc->yield(
			privmsg => $channel,
			PURPLE . "Hi I am $nick the $channel channel bot (v$VERSION), please op me" . NORMAL
		);
		return;
	}

	# TODO for now it is on every channel
	# but it should work with some database

	if ( $config->{trusted}{$nick} ) {
		set_op( $irc, $channel, $nick );

		#turn off Welcome for op's joining
		# $irc->yield( privmsg => $channel, YELLOW . 'Welcome ' . $nick . NORMAL
	} elsif ( $config->{halfop}{$nick} ) {
		set_hop( $irc, $channel, $nick );
	}

	#Advise machine generated nicks to change them
	elsif ( $nick =~ /^(user|mib)_/ ) {
		new_user( $irc, $channel, $nick );

		#dont send messages to machine generated nicks
		return;
	}

	#ToDo SPAM should this be commented out? +/- 1 for Padre
	if ( $dt->month eq $birthday->month ) {
		if ( $dt->day >= $birthday->day - 1 && $dt->day <= $birthday->day + 1 ) {
			new_user( $irc, $channel, $nick );
		}
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
# event handler for nick change
#######
sub irc_nick {
	my $old_nick = ( split /!/, $_[ARG0] )[0];
	my $nick = $_[ARG1];

	###
	#TODO check array againts Padre as this only works for hard coded channel
	###
	my $channel = $config->{channels}[0];
	say $old_nick. ' changed /nick to: ' . $nick;


	if ( $config->{trusted}{$nick} ) {
		set_op( $irc, $channel, $nick );

		#this should be left on showing an op after a /nick
		$irc->yield( privmsg => $channel, BOLD . 'Welcome ' . $nick . NORMAL );

	} elsif ( $config->{halfop}{$nick} ) {
		set_hop( $irc, $channel, $nick );

		#this should be left on showing an hop after a /nick
		$irc->yield( privmsg => $channel, BOLD . 'Welcome ' . $nick . NORMAL );

	}

	#Assume machine generated nicks are new user's to IRC
	elsif ( $nick =~ /^(user|mib)_/ ) {
		new_user( $irc, $channel, $nick );

		#dont send messages to machine generated nicks
		return;
	}

	else {
		$irc->yield( privmsg => $channel, BOLD . 'Welcome ' . $nick . NORMAL );
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

sub set_hop {
	my ( $irc, $channel, $nick ) = @_;
	if ( ref $channel and ref($channel) eq 'ARRAY' ) {
		($channel) = @$channel;
	}
	say 'Making ' . $nick . ' a hop on ' . $channel;
	$irc->yield( mode => $channel => ' +h ' . $nick );

	return;
}

sub set_dehop {
	my ( $irc, $channel, $nick ) = @_;
	if ( ref $channel and ref($channel) eq 'ARRAY' ) {
		($channel) = @$channel;
	}
	say 'Rescinded ' . $nick . ' as hop on ' . $channel;
	$irc->yield( mode => $channel => ' -h ' . $nick );

	return;
}

sub set_ban {
	my ( $irc, $channel, $nick ) = @_;
	if ( ref $channel and ref($channel) eq 'ARRAY' ) {
		($channel) = @$channel;
	}
	say 'Added ' . $nick . ' to ban list on ' . $channel;
	$irc->yield( mode => $channel => ' +b ' . $nick );
	$irc->yield( kick => $channel, $nick );
	return;
}

sub new_user {
	my ( $irc, $channel, $nick ) = @_;
	my @info;
	push @info, "You have found #Padre, the Perl IDE.";
	push @info, "It's nice to see you, some guidance follows, which may be of help to you.";
	push @info,
		"Please Ask your question and wait, 'Please be Patient', do not give up after two minutes. Remember this is a community channel. May be you just popied by to say Hi that's ok to. ";
	push @info,
		"You did look in our wiki -> http://padre.perlide.org/trac/wiki. Don't forget to Register, Login and join in.";
	push @info, 'If you need to show us code/errors, Please use the no-paste service http://scsys.co.uk:8001 ';
	push @info, ORANGE . 'IRC help' . NORMAL;
	push @info, ORANGE . '/HELP' . NORMAL . ' http://www.ircbeginner.com/ircinfo/ircc-commands.html';
	push @info,
		  ORANGE
		. 'INFO: Please change your machine generated nickname '
		. NORMAL
		. $nick
		. ORANGE
		. ' for continuity, this will enable our '
		. $irc->nick_name()
		. ' to relay any messages left for you.'
		. NORMAL;

	push @info, 'Example: /nick new-nickname (limit 9 characters) ' . GREEN . ' Thank You' . NORMAL;
	$irc->yield( privmsg => $nick => $_ ) for @info;

	$irc->yield( privmsg => $channel, ORANGE . "Welcome $nick" . NORMAL );
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


#######
# trac stuff below
###################
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


