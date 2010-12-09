package Plack::Middleware::Debug::DBIC::QueryLog;

use Moo;
use Plack::Util;
use Plack::Middleware::DBIC::QueryLog;
use Text::MicroTemplate;

extends 'Plack::Middleware::Debug::Base';

our $VERSION = '0.04';
sub PSGI_KEY { 'plack.middleware.dbic.querylog' }

has 'sqla_tree_class' => (
  is => 'ro',
  default => sub {'SQL::Abstract::Tree'},
);

has 'sqla_tree_args' => (
  is => 'ro',
  default => sub { +{profile => 'html'} },
);

has 'sqla_tree' => (
  is => 'ro',
  lazy => 1,
  builder => '_build_sqla_tree',
);

sub _build_sqla_tree {
  Plack::Util::load_class($_[0]->sqla_tree_class)
    ->new($_[0]->sqla_tree_args);
}

has 'querylog_class' => (
  is => 'ro',
  default => sub {'DBIx::Class::QueryLog'},
);

has 'querylog_args' => (
  is => 'ro',
  default => sub { +{} },
);

sub create_querylog {
  Plack::Util::load_class($_[0]->querylog_class)
    ->new($_[0]->querylog_args);
}

sub find_or_create_querylog {
  $env->{+PSGI_KEY} ||= $self->create_querylog;
}

has template => (
  is => 'ro',
  builder => '_build_template',
);

sub _build_template {
  __PACKAGE__->build_template(join '', <DATA>);
}

has 'querylog_analyzer_class' => (
  is => 'ro',
  default => sub { 'DBIx::Class::QueryLog::Analyzer' },
);

sub querylog_analyzer_for {
  my ($self, $ql) = @_;
  Plack::Util::load_class($_[0]->querylog_analyzer_class)
    ->new({querylog => $ql});
}

sub run {
  my ($self, $env, $panel) = @_;
  my $querylog = $self->find_or_create_querylog;

  $panel->title('DBIC::QueryLog');

  return sub {
    my $analyzer = $self->querylog_analyzer_for($querylog);
    if(my @sorted_queries = $analyzer->get_sorted_queries) {
      $panel->nav_subtitle(sprintf('Total Time: %.6f', $querylog->time_elapsed));
      $panel->content(sub { $template->($querylog, $querylog_analyzer, $sqla_tree) });
    } else {
      $panel->nav_subtitle("No SQL");
      $panel->content("No DBIC log information");
    }
  };
}

=head1 NAME

Plack::Middleware::Debug::DBIC::QueryLog - DBIC Query Log and Query Analyzer 

=head2 SYNOPSIS

Adds a debug panel and querylog object for logging L<DBIx::Class> queries.  Has
support for L<Catalyst> via a L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>
compatible trait, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>.

    use Plack::Builder;

    my $app = ...; ## Build your Plack App

    builder {
        enable 'Debug';
        enable 'Debug::DBIC::QueryLog',
          querylog_args => {passthrough => 1};
        $app;
    };

And in you L<Catalyst> application, if you are also using
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>

    package MyApp::Web::Model::Schema;
    use parent 'Catalyst::Model::DBIC::Schema';

	__PACKAGE__->config({
        schema_class => 'MyApp::Schema',
        traits => ['QueryLog::AdoptPlack'],
        ## .. rest of configuration
	});

=head1 DESCRIPTION

L<DBIx::Class::QueryLog> is a tool in the L<DBIx::Class> software ecosystem
which benchmarks queries.  It lets you log the SQL that L<DBIx::Class>
is generating, along with bind variables and timestamps.  You can then pass
the querylog object to an analyzer (such as L<DBIx::Class::QueryLog::Analyzer>)
to generate sorted statistics for all the queries between certain log points.

Query logging in L<Catalyst> is supported for L<DBIx::Class> via a trait for
L<Catalyst::Model::DBIC::Schema> called
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>.  This trait will
log all the SQL used by L<DBIx::Class> for a given request cycle.  This is very
useful since it can help you identify troublesome or bottlenecking queries.

However, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog> does not provide
out of the box outputting of your analyzed query logs.  Usually you need to
add a bit of templating work to the bottom of your webpage footer, or dump the
output to the logs.  We'd like to provide a lower ceremony experience.

Additionally, it would be nice if we could provide this functionality for all
L<Plack> based applications, not just L<Catalyst>.  Ideally we'd play nice with
L<Plack::Middleware::Debug> so that the table of our querylog would appear as
a neat Plack based Debug panel.  This bit of middleware provides that function.

Basically we create a new instance of L<DBIx::Class::QueryLog> and place it
into C<< $env->{'plack.middleware.debug.dbic.querylog'} >> so that it is accessible by
all applications running inside of L<Plack>.  You need to 'tell' your application's
instance of L<DBIx::Class> to use this C<$env> key and make sure you set
L<DBIx::Class>'s debug object correctly:

    my $querylog = $env->{'plack.middleware.debug.dbic.querylog'};
    $schema->storage->debugobj($querylog);
    $schema->storage->debug(1);

That way when you view the debug panel, we have SQL to review.

If you are using L<Catalyst> and a modern L<Catalyst::Model::DBIC::Schema> you
can use the trait
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>, which is
compatible with L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>.  See the
L</SYNOPSIS> example for more details.

=head1 OPTIONS

This debug panel defines the following options.

=head2 querylog

Takes a L<DBIx::Class::QueryLog> object, which is used as the querylog for the
application.  If you don't provide this, we will build one automatically, using
L</querylog_args> if provided.  Generally you will use this only if you are
instantiating a querylog object outside your L<Plack> based application, such
as in an IOC container like L<Bread::Board>.

=head2 querylog_args

Takes a HashRef which is passed to L<DBIx::Class::QueryLog> at construction.

=head1 SEE ALSO

L<Plack::Middleware::Debug>, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>,
L<Catalyst::Model::DBIC::Schema>, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__
% my ($querylog, $querylog_analyzer, $sqla_tree) = @_;
% my $qcount = $querylog->count;
% my $total = sprintf('%.6f', $querylog->time_elapsed);
% my $average_time = sprintf('%.6f', ($querylog->time_elapsed / $qcount));
<style>
  #plDebug .select { color:red }
  #plDebug .insert-into { color:red }
  #plDebug .delete-from { color:red }
  #plDebug .where { color:green }
  #plDebug .join { color:blue }
  #plDebug .on { color:DodgerBlue  }
  #plDebug .from { color:purple }
  #plDebug .order-by { color:DarkCyan }
  #plDebug .placeholder {color:gray}
</style>
<div>
  <br/>
  <p>
    <ul>
      <li>Total Queries Ran: <b><%= $qcount %></b></li>
      <li>Total SQL Statement Time: <b><%= $total %> seconds</b></li>
      <li>Average Time per Statement: <b><%= $average_time %> seconds</b></li>
    </ul>
  </p>
  <table id="box-table-a">
    <thead class="query_header">
      <tr>
        <th style="padding-left:4px">Time</th>
        <th style="padding-left:15px; padding-right:15px">Percent</th>
        <th>SQL Statements</th>
      </tr>
    </thead>
    <tbody>
% my $even = 1;
% for my $q (@{$querylog_analyzer->get_sorted_queries}) {
%   my $tree_info = Text::MicroTemplate::encoded_string($sqla_tree->format($q->sql, $q->params));
       <tr <%= $even ? "class=plDebugOdd":"plDebugEven" %> >
        <td style="padding-left:8px"><%= sprintf('%.7f', $q->time_elapsed) %></td>
        <td style="padding-left:21px"><%= sprintf('%.2f', (($q->time_elapsed / $total ) * 100 )) %>%</td>
        <td style="padding-left:6px; padding-bottom:6px"><%= $tree_info %></td>
      </tr>
% $even = $even ? 0:1;
% }
    </tbody>
  </table>
</div>
<br/>

