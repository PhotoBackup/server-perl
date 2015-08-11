package Net::PhotoBackup::Server;

use 5.008001;
use strict;
use warnings;

=encoding utf-8

=head1 NAME

    Net::PhotoBackup::Server - perl5 server for L<https://photobackup.github.io/>

=head1 SYNOPSIS

    # Initial setup of server config.
    photobackup.pl init

    # Launch server using config.
    photobackup.pl run

=head1 DESCRIPTION

    Net::PhotoBackup::Server provides a server and startup script for
    L<https://photobackup.github.io/> It was developed by reading the API docs at
    L<https://github.com/PhotoBackup/api/blob/master/api.raml> and looking at
    the sourcecode of the python implementations at
    L<https://github.com/PhotoBackup/server-bottle> and
    L<https://github.com/PhotoBackup/server-flask>

=cut

use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use Digest::SHA ();
use File::HomeDir ();
use Plack::Request;
use Plack::Runner;

our $VERSION = "0.01";
sub version { $VERSION }

=head2 new()

    Constructor.

    Any args will be added to $self, overriding any defaults.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    return bless {
        config_file => File::Spec->catfile(File::HomeDir->my_home, '.photobackup'),
        %args,
    }, $class;

}

=head2 init()

    Create, or recreate the user's config file.

    The user will be prompted for the following information:

    Media root - Directory where the pictures will be stored.

    Server password - The password to use for all HTTP operations.

    Server port - Defaults to 8420.

    Some rudimentary checking will be done for valid input.

=cut

sub init {
    my $self = shift;

    my $config = $self->config;

    do { 
        print "Media root - Where should the pictures be stored" . ($config->{MediaRoot} ? " [$config->{MediaRoot}]: " : ": ");
        my $media_root = <STDIN>;
        chomp $media_root;
        $config->{MediaRoot} = $media_root unless $media_root eq '';
    }
    while ( ! $config->{MediaRoot} );

    my $password;
    do { 
        print "Server password - The password required for HTTP operations: ";
        system "stty -echo";
        $password = <STDIN>;
        chomp $password;
        print "\n";
        system "stty echo";
    }
    while ( ! $password );
    $config->{Password} = Digest::SHA::sha256_hex $password;

    do {
        print "Server port [" . ($config->{Port} || 8420) . "]: ";
        my $port = <STDIN>;
        chomp $port;
        $config->{Port} = $port eq '' ? ($config->{Port} || 8420) : $port =~ m{ \A \d+ \z }xms ? $port : undef;
    }
    while ( ! $config->{Port} );

    $self->config($config);

    print "\nConfig written. Launch PhotoBackup server with 'photobackup.pl run'\n";
}

=head2 config()

    Read and write server config file.

    Returns undef if config file doesn't exist, or doesn't hold all required
    data.

    The config will be written to ~/.photobackup in INI format.

    I'm reading and writing this simple INI file manually rather than using a
    CPAN module so as to reduce the dependencies.

=cut

sub config {
    my $self   = shift;
    my $config = shift;

    my @required_keys = qw( MediaRoot Password Port );

    if ($config) {

        foreach my $key (@required_keys) {
            die "config() config hashref arg missing '$key'. Got " . Dumper($config) unless $config->{$key};
        }

        open my $FH, '>', $self->{config_file}
            or die "config() unable to open config file '$self->{config_file}' for writing - $!";

        print $FH "# Settings for Net::PhotoBackup::Server - perldoc Net::PhotoBackup::Server\n";
        print $FH "[photobackup]\n";
        foreach my $key (@required_keys) {
            print $FH "$key=$config->{$key}\n";
        }

        close $FH
            or die "config() unable to close config file '$self->{config_file}' after writing - $!";
    }
    else {
        if ( -f "$self->{config_file}" ) {
            open my $FH, '<', $self->{config_file}
                or die "config() unable to open config file '$self->{config_file}' for reading - $!";
            my $in_section;
            LINE: foreach my $line ( <$FH> ) {
                chomp $line;
                if ( $in_section ) {
                    if ( $line =~ m{ \A \s* \[ }xms ) {
                        last LINE;
                    }
                    # MediaRoot can contain everything but NUL.
                    if ( $line =~ m{ \A \s* MediaRoot \s* = \s* ([^\0]+) \s* \z }xms ) {
                        $config->{MediaRoot} = $1;
                    }
                    # Password is 64 hex digits only.
                    elsif( $line =~ m{ \A \s* Password \s* = \s* ([0-9A-F]){64} \s* \z }ixms ) {
                        $config->{Password} = $1;
                    }
                    # Port is just digits.
                    elsif ( $line =~ m{ \A \s* Port \s* = \s* (\d+) \s* \z }xms ) {
                        $config->{Port} = $1;
                    } 
                }
                elsif ( $line =~ m{ \A \s* \[ photobackup \] \s* \z }xms ) {
                    $in_section = 1;
                    next LINE;
                }
                else {
                    next LINE;
                }
            }
            foreach my $key (@required_keys) {
                die "config() config hashref from file '$self->{config_file}' missing '$key'. Got " . Dumper($config) unless $config->{$key};
            }
        }
    }
    return $config;
}

=head2 run()

Launch the PhotoBackup web service using config from the conf file.

=cut

sub run {
    my $self = shift;

    $self->init unless $self->config;

    my $config = $self->config;

    my @args = (
        app        => $self->get_app,
        daemonize  => 1
        env        => 'deployment',
        port       => $config->{Port},
        server     => 'Starman',
        version_cb => \&version,
    );

    my $runner = Plack::Runner->new(@args);
  
    $runner->run; 
     
}

=head2 app()

Return the PSGI application subref.

=cut

sub app {
    my $self = shift;
    my $config = shift || $self->config;

    return sub {
        my $env = shift; # PSGI env
 
        my $req = Plack::Request->new($env);
        my $path_info = $req->path_info;
        my $method = $req->method;

        if ( $path_info eq '' || $path_info eq '/' ) {
            # GET / : Return a HTML doc describing PhotoBackup.

            # POST / : Store new image file in MediaRoot. Needs password.
        }
        elsif ( $path_info eq '/test' ) {

        }


        # POST /test : Check password, then attempt to write test file to MediaRoot.
    };
}

=head2 index_html()

Returns the info page about PhotoBackup.

Copied from: https://raw.githubusercontent.com/PhotoBackup/server-flask/master/templates/index.html
@f47b8ffb4c3aa223071e9f0acde46f7b1cd62ef9

=cut

sub index_html {
q{
<!DOCTYPE html>
<!--
    Copyright (C) 2013-2015 Stéphane Péchard.

    This file is part of PhotoBackup.

    PhotoBackup is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    PhotoBackup is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with PhotoBackup. If not, see <http://www.gnu.org/licenses/>.
-->

<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="PhotoBackup is used to backup
    your pictures from a mobile device to your own server. OWN YOUR DATA!">

    <title>PhotoBackup server</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
</head>
<body>

    <div class="container">
        <div style="text-align:center;">
            <h1>PhotoBackup</h1>
            <p class="lead">Backup your pictures from your mobile device to your server.<br />OWN YOUR DATA!</p>
        </div>

        <div class="jumbotron">
            <p>PhotoBackup works with two applications, a client and a server,
                dedicated to the backup of the pictures you take on your
                mobile device to your own server.</p>
            <p>You need four little steps:</p>

            <ol style="font-size:1.4em;">
                <li><a href="http://play.google.com">Install a mobile application</a> ;</li>
                <li><a href="https://github.com/stephanepechard/photobackup-servers">
                    Install one of the server applications</a> ;
                </li>
                <li>Take pictures as usual and let the magic happens in background ;</li>
                <li>Keep your pictures safe on your server.</li>
            </ol>
        </div>
    </div>

</body>
</html>
};
}

1;

__END__

=head1 LICENSE

Copyright (C) 2015 Dave Webb.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dave Webb E<lt>github@d5ve.comE<gt>

=cut

