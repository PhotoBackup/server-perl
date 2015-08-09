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

our $VERSION = "0.01";

=head2 new()

    Constructor.

    Takes no args.

=cut

sub new {
    my $class = shift;

    return bless {}, $class;

}

=head2 init()

    Create, or recreate the user's config file.

    The user will be prompted for the following information:

    Media root - Directory where the pictures will be stored.

    Server password - The password to use for all HTTP operations.

    Server port - Defaults to 8420.

    The config will be written to ~/.photobackup in ini format.

=cut

sub init {
    my $self = shift;

    my $config = $self->config;

    print "Media root - Where should the pictures be stored" . ($config->{MediaRoot} ? " [$config->{MediaRoot}]: " : ": ");
    my $config->{MediaRoot} = <STDIN>;
    chomp $config->{MediaRoot};

    print "Server password - The password required for HTTP operations: ";
    my $password = <STDIN>;
    chomp $password;
    $config->{Password} = Digest::SHA::sha256_hex $password;

    print "Server port [" . ($config->{Port} || 8420) . "]: ";
    my $config->{Port} = <STDIN>;
    chomp $config->{Port};

    $self->config($config);

    print "\nConfig written. Launch PhotoBackup server with 'photobackup.pl run'\n";
}

=head2 config()

    Read and write server config file.

    Returns undef if config file doesn't exist, or doesn't hold all required
    data.

=cut

sub config {
    
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

