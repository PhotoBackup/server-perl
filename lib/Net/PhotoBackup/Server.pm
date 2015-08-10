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

use File::HomeDir ();
use Digest::SHA ();
use Data::Dumper; $Data::Dumper::Sortkeys = 1;

our $VERSION = "0.01";

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

1;

__END__

=head1 LICENSE

Copyright (C) 2015 Dave Webb.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dave Webb E<lt>github@d5ve.comE<gt>

=cut

