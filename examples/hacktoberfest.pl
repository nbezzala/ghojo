#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Ghojo;

use Data::Dumper;

my $hash = {
	username => 'briandfoy',
	password => 'tritonX100',
	};

my $ghojo = Ghojo->new( $hash );
$ghojo->logger->level( $ENV{GHOJO_LOG_LEVEL} // 'TRACE' );

my $callback = sub ( $item ) {
	unless( ref $item eq ref {} ) {
		$ghojo->logger->error( "Not a hashref!" );
		return;
		}
	my( $user, $repo ) = split m{/}, $item->{full_name};
	my $owner = $item->{owner}{login};
	return unless $ghojo->logged_in_user eq $owner;
	say "Repo is $item->{full_name}";

	# get the labels for that repo
	my $repo = get_repo_object( $owner, $repo );

	my $labels = $repo->labels;
	my %labels = map { $_->@{ qw(name color) } } $labels->@*;
	unless( exists $labels{'Hacktoberfest'} ) {
		say "\tHacktoberfest label does not exist";
		$repo->create_label( 'Hacktoberfest', 'ff5500' );
		}

	if( exists $labels{'bug'} ) {
		say "\tbug label does exist";
		$ghojo->update_label( 'bug',  'New bug', 'ff0000' );
		}

	if( exists $labels{'New bug'} ) {
		say "\tbug label does exist";
		$ghojo->update_label( 'New bug',  'bug', '00ff00' );
		}

	return 1;
	};

my $query = {};

my $repos = $ghojo->repos( $callback, $query );

sub prompt_for_password {
	state $rc = require Term::ReadKey;
	Term::ReadKey::ReadMode('noecho');
	print "Type in your secret password: ";
	my $password = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
	chomp $password;
	$password;
	}
