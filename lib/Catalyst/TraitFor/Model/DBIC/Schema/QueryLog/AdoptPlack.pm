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
        my $querylog = $ctx->engine->env->{'plack.middleware.dbic.querylog'} ||
          DBIx::Class::QueryLog->new($self->querylog_args);
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

    TBD

=head1 DESCRIPTION

    TBD

=head1 OPTIONS

    TBD

=head1 SEE ALSO

L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>, L<Catalyst::Model::DBIC::Schema>,
L<Plack::Middleware::Debug>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
