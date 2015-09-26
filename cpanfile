requires 'perl', '5.008001';

requires 'Data::Dumper';
requires 'Digest::SHA';
requires 'File::Copy';
requires 'File::HomeDir';
requires 'File::Spec';
requires 'Getopt::Long';
requires 'Plack';
requires 'Pod::Usage';
requires 'Starman';
requires 'Try::Tiny';

on 'test' => sub {
    requires 'autodie';
    requires 'Test::More', '0.98';
    requires 'HTTP::Tiny';
};

on 'build' => sub {
    requires 'Pod::Markdown::Passthrough';
};

