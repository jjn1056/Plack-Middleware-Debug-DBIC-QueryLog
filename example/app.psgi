#!/usr/bin/env perl

use strictures 1;
use Plack::Builder;
use Example::Schema;

builder {
  enable 'Debug', panels =>['DBIC::QueryLog'];
  sub {
    return [
      200, ['Content-Type' =>'text/html'],
      [
        '<html>',
          '<head>',
            '<title>Hello World</title>',
          '</head>',
          '<body>',
            '<h1>Hello World</h1>',
          '</body>',
        '</html>',
      ],
    ];
  };
};
