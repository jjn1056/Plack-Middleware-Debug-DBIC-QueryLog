use strict;
use warnings;
use Test::More;

use_ok 'Plack::Middleware::Debug::DBIC::QueryLog';
use_ok 'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack';

done_testing;
