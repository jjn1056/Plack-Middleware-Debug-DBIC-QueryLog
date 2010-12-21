#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'DBIx::Class::QueryLog';
requires 'DBIx::Class::QueryLog::Analyzer';
requires 'SQL::Abstract' => '1.70';
requires 'Moo' => '0.009004';

test_requires 'Test::Fatal';
test_requires 'Test::More' => '0.96';

all_from 'lib/Plack/Middleware/Debug/DBIC/QueryLog.pm';
require 'maint/Makefile.PL.include'
  if $Module::Install::AUTHOR;

WriteAll;

