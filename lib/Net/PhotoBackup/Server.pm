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

our $VERSION = "0.01";

1;

__END__

=head1 LICENSE

Copyright (C) Dave Webb.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dave Webb E<lt>github@d5ve.comE<gt>

=cut

