#!/usr/bin/env perl

use strictures 1;
use Plack::Builder;
use Plack::Middleware::Debug::DBIC::QueryLog;
use Test::DBIx::Class
  -schema_class => 'Example::Schema',
  qw(:resultsets);

User->create({email =>'jjnapiork@cpan.org'});

builder {
  enable 'Debug', panels =>['DBIC::QueryLog'];
  sub {
    my $env = shift;
    my $schema = Schema->clone;
    my $querylog = $env->{+Plack::Middleware::Debug::DBIC::QueryLog::PSGI_KEY};

    $schema->storage->debugobj($querylog);

    return [
      200, ['Content-Type' =>'text/html'],
      [
        '<html>',
          '<head>',
            '<title>Hello World</title>',
          '</head>',
          '<body>',
            '<h1>Hello World</h1>',
            map({ '<p>'. $_->email. '</p>' } $schema->resultset('User')->all),
          '</body>',
        '</html>',
      ],
    ];
  };
};

## DBIC_TRACE=1 plackup -I lib -I example/lib/ example/app.psgi
