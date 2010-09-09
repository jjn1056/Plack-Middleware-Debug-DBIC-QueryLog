use strict;
use warnings;

use inc::Module::Install 1.00;

requires 'parent';
requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'DBIx::Class::QueryLog';
requires 'DBIx::Class::QueryLog::Analyzer';

build_requires 'Test::More' => '0.96';

all_from 'lib/Plack/Middleware/Debug/DBIC/QueryLog.pm';
readme_pod_from 'lib/Plack/Middleware/Debug/DBIC/QueryLog.pm';
auto_manifest;
auto_install;
githubmeta;
WriteAll;
