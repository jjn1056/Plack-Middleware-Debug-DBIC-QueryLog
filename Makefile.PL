use strict;
use warnings;
use inc::Module::Install 1.00;

all_from 'lib/Plack/Middleware/Debug/DBIC/QueryLog.pm';
requires 'parent';
requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'DBIx::Class::QueryLog';
requires 'DBIx::Class::QueryLog::Analyzer';
requires 'SQL::Abstract';

test_requires 'Test::More' => '0.96';

require 'maint_Makefile.PL.include'
  if $Module::Install::AUTHOR;

WriteAll;

