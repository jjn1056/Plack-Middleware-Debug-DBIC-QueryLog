package Plack::Middleware::Debug::DBIC::QueryLog;
use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = "0.01";

use 5.008;
use strict;
use warnings;

use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;
use Plack::Util::Accessor qw(querylog querylog_args);

=head1 NAME

Plack::Middleware::Debug::DBIC::QueryLog - Log DBIC Queries

=head2 SYNOPSIS

Adds a debug panel and querylog object for logging L<DBIx::Class> queries.  Has
support for L<Catalyst> via a L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>
compatible trait, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>.


    use Plack::Builder;

    my $app = ...; ## Build your Plack App

    builder {
        enable 'Debug::DBIC::QueryLog', querylog_args => {passthrough => 1}; 
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

    1;

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

        my $querylog = $ctx->engine->env->{'plack.middleware.debug.dbic.querylog'};
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

my $template = __PACKAGE__->build_template(join '', <DATA>);
sub run {
    my ( $self, $env, $panel ) = @_;
    my $querylog = $self->querylog ||
      DBIx::Class::QueryLog->new($self->querylog_args || {});
    $env->{'plack.middleware.debug.dbic.querylog'} = $querylog;
    $panel->title('Catalyst::DBIC::QueryLog');
    return sub {
        my $querylog_analyzer = DBIx::Class::QueryLog::Analyzer->new({
            querylog => $querylog,
        });
        if(@{$querylog_analyzer->get_sorted_queries}) {
            $panel->nav_subtitle(sprintf('Total Seconds: %.6f', $querylog->time_elapsed));
            $panel->content(sub {
                $self->render($template, [$querylog, $querylog_analyzer]);
            });
        } else {
            $panel->nav_subtitle("No SQL");
            $panel->content("No DBIC log information");
        }
    };
}

1;

__DATA__
% my ($querylog, $querylog_analyzer) = @{shift @_};
% my $qcount = $querylog->count;
% my $total = sprintf('%.6f', $querylog->time_elapsed);

<style>
#querylog_box dt,
 #querylog_box dd {
  display: block;
  float:left;
  margin: 5px 5px 5px 5px;
}
#querylog_box dt {
  clear:both;
  width: 120px;
  text-align:right;
  font-weight: bold;
}
</style>

<div id="querylog_box">
  <table>
    <thead>
      <tr>
        <th>Seconds</th>
        <th>%</th>
        <th>SQL</th>
      </tr>
    </thead>
    <tbody>
% my $odd = 0;
% for my $q (@{$querylog_analyzer->get_sorted_queries}) {
       <tr <%= $odd ? "class='odd'":"" %> >
        <td><%=  sprintf('%.6f', $q->time_elapsed) %></td>
        <td><b><%=  sprintf('%.1f', (($q->time_elapsed / $total ) * 100 )) %>%</b></td>
        <td><%=  $q->sql %> : (<%=  join ',', @{$q->params} %>)</td>
      </tr>
% $odd = $odd ? 0:1;
% }
    </tbody>
  </table>
  <div class="summary-info">
    <dl>
      <dt>Total SQL Time</dt>
      <dd><%= $total %> seconds</dd>
      <dt>Total Queries</dt>
      <dd><%= $qcount %></dd>
      <dt>Avg Statement Time</dt>
% my $average_time = sprintf('%.6f', ($querylog->time_elapsed / $qcount));
      <dd><%= $average_time %> seconds</dd>
    </dl>
  </div>
</div>
