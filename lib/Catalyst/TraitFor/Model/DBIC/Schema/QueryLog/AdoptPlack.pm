package Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack;
our $VERSION = "0.01";

use namespace::autoclean;
use Moose::Role;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';
use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;

with 'Catalyst::Component::InstancePerContext';

has 'querylog' => (
    is  => 'rw',
    init_arg => undef,
    isa => 'DBIx::Class::QueryLog',
);

has 'querylog_analyzer' => (
    is         => 'rw',
    isa        => 'DBIx::Class::QueryLog::Analyzer',
    lazy_build => 1
);

sub _build_querylog_analyzer {
    my $self = shift;

    return DBIx::Class::QueryLog::Analyzer->new(
        { querylog => $self->querylog } );
}

sub build_per_context_instance {
    my ( $self, $ctx ) = @_;

    if(defined $ctx->engine->env) {
        my $querylog = $ctx->engine->env->{'plack.middleware.dbic.querylog'};
        $self->querylog($querylog);
        $self->clear_querylog_analyzer;

        my $schema = $self->schema;
        $schema->storage->debugobj($querylog);
        $schema->storage->debug(1);
    }

    return $self;
}

1;
