use strict;
use Test::More 0.98;
use autodie;

use Data::Dumper;
use File::Spec ();
use File::Temp ();
use HTTP::Tiny;
use Net::PhotoBackup::Server;

# TODO: See if all the tests can be run without actually needing a daemon running.

# Always cleanup after test, even for Ctrl-c/kill etc.
my $CLEANEDUP;
$SIG{TERM} = $SIG{INT} = $SIG{QUIT} = $SIG{HUP} = sub { cleanup() };

my $test_dir    = File::Temp::tempdir( CLEANUP => 1 );
my $config_file = File::Spec->catfile( $test_dir, '.photobackup' );
my $pid         = File::Spec->catfile( $test_dir, '.photobackup.pid' );
my $media_root  = File::Spec->catdir( $test_dir, 'photobackup' );
mkdir $media_root;

open my $fh, '>', $config_file;
print $fh qq{
# Settings for Net::PhotoBackup::Server - perldoc Net::PhotoBackup::Server
[photobackup]
MediaRoot=$media_root
Password=ae1413078f26b37974431e7c1d973da2d1fab1d5839707823ba800bafdf746dfaeb9bf29b4aba3a3c3108e8d712aceb7048b4a007b521bf9aff127621374a5b3
Port=58420
};
close $fh;

my $server = Net::PhotoBackup::Server->new( config_file => $config_file, pid => $pid, env => 'deployment', daemonize => 0 );
if ( my $child = fork ) {
    # Parent - sleep to allow child to start server.
    sleep 1;
}
else {
    # Child - launch server in foreground.
    $server->run;
    exit;
}

my $response = HTTP::Tiny->new( max_redirect => 0 )->get('http://127.0.0.1:58420/');
is( $response->{status}, 301, "Server is responding to GET /" );
is( $response->{headers}->{location}, 'https://photobackup.github.io/', "GET / redirects to https://photobackup.github.io/" );

$response = $response = HTTP::Tiny->new->post_form( 'http://127.0.0.1:58420/test', {} );
is( $response->{status}, 403, "POST /test without password fails" );

$response = $response = HTTP::Tiny->new->post_form( 'http://127.0.0.1:58420/test', { password => 'WRONG' } );
is( $response->{status}, 403, "POST /test with incorrect password fails" );

$response = $response = HTTP::Tiny->new->post_form( 'http://127.0.0.1:58420/test', { password => 'barry' } );
ok( $response->{success}, "POST /test with correct password succeeds" );

$server->stop;

done_testing;

exit;

END { cleanup() unless $CLEANEDUP; }

sub cleanup {
    $CLEANEDUP++;

    $server->stop;
}
