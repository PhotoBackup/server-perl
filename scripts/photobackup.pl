#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

    photobackup.pl - Setup and run PhotoBucket server.

=head1 SYNOPSIS

    photobucket.pl init
    photobucket.pl run
    photobucket.pl (-h | --help)
    photobackup.pl --version

    # Full docs
    perldoc Net::PhotoBackup::Server 
=cut

use Getopt::Long;
use Net::PhotoBackup::Server;
use Pod::Usage;

Getopt::Long::GetOptions(
    'help|?'  => sub {pod2usage},
    'version' => sub {
        print "Net::PhotoBackup::Server $Net::PhotoBucket::VERSION\n";
        exit;
    }
);

pod2usage() unless @ARGV == 1;
my $action = shift;
pod2usage() unless $action =~ m{ \A (?: init | run ) }xms;

my $server = Net::PhotoBackup::Server->new();
if ( $action eq 'init' || $server->needs_init ) {
    $server->init();
}
elsif ( $action eq 'run' ) {
    $server->run();
}
exit;

__END__

=head1 AUTHOR

Dave Webb L<github@d5ve.com>

=head1 LICENSE

Copyright (C) 2015 Dave Webb

photobackup.pl is free software. You may use and distribute this script under
the same terms as Perl itself.

=cut
