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
    isa => 'DBIx::Class::QueryLog',
);
has 'querylog_args' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
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

    ## Needs to better handle the 'pass through from conf option, and if
    ## there is not engine, such as when you are doing commandline stuff
    if(defined $ctx->engine->env) {
        my $querylog = $ctx->engine->env->{'plack.middleware.debug.dbic.querylog'} ||
          $self->querylog || DBIx::Class::QueryLog->new($self->querylog_args);
        $self->querylog($querylog);
        $self->clear_querylog_analyzer;

        my $schema = $self->schema;
        $schema->storage->debugobj($querylog);
        $schema->storage->debug(1);
    }

    return $self;
}

1;

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack - Use a Plack Middleware QueryLog

=head2 SYNOPSIS

    package MyApp::Web::Model::Schema;
    use parent 'Catalyst::Model::DBIC::Schema';

	__PACKAGE__->config({
        schema_class => 'MyApp::Schema',
        traits => ['QueryLog::AdoptPlack'],
        ## .. rest of configuration
	});

=head1 DESCRIPTION

This is a trait for L<Catalyst::Model::DBIC::Schema> which adopts a L<Plack>
created L<DBIx::Class::QueryLog> and logs SQL for a given request cycle.  It is
intended to be compatible with L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>
which you may already be using.

=head1 OPTIONS

This model defines the following options.

=head2 querylog

Takes a L<DBIx::Class::QueryLog> object, which is used as the querylog for the
application.  Generally the whole point of this trait is to adopt the query log
provided by the L<Plack> middleware, but if you have special needs you can set
an instance here.  You may wish to do this if you have complicated instatiation
needs.

=head2 querylog_args

Takes a HashRef which is passed to L<DBIx::Class::QueryLog> at construction, 
if needed.

=head1 SEE ALSO

L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>, L<Catalyst::Model::DBIC::Schema>,
L<Plack::Middleware::Debug>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
