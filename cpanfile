requires 'perl', '5.008001';

requires 'Data::Dumper';
requires 'Digest::SHA';
requires 'File::HomeDir';
requires 'Getopt::Long';
requires 'Plack';
requires 'Pod::Usage';
requires 'Starman';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

