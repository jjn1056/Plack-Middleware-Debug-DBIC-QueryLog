use strict;
use warnings;

use inc::Module::Install 1.00;

requires 'parent';
requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'DBIx::Class::QueryLog';
requires 'DBIx::Class::QueryLog::Analyzer';
## requires 'SQL::Abstract';

build_requires 'Test::More' => '0.96';

all_from 'lib/Plack/Middleware/Debug/DBIC/QueryLog.pm';
readme_markdown_from_pod;
auto_set_repository;
auto_set_homepage;
auto_manifest;
auto_license;
auto_install;
WriteAll;

