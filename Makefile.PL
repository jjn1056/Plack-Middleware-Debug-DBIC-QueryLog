#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

if(
  my $v = eval q{
    use Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack;
    $Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack::VERSION
  }
) {
  if($v < 0.03) {
    warn <<MSG;

###############################################################################
##  WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING  ##
###############################################################################

Your version of Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack
is too old.  Please upgrade it (should be 100% drop in replacement).  Otherwise
you will not log queries probably for your Catalyt based applications.

If you are using this in a custom application please change your Makefile.PL to
use a more modern version.  If you are seeing this message while installing a
third party application, please log it as a bug with the third party.

Sorry for the trouble.  --THE AUTHOR

###############################################################################
##  WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING  ##
###############################################################################

MSG

     feature(
      'upgrade incompatible versions',
       -default => 1,
       'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack' => '0.03',
     );
  }
}

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

