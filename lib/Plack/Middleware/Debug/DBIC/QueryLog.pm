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

    use Plack::Builder;

    my $app = ...; ## Build your Plack App

    builder {
        enable 'Debug::DBIC::QueryLog', querylog_args => {passthrough => 1}; 
        $app;
    };

You need to 'tell' your applications instance of L<DBIx::Class> to use the 
L<DBIx::Class::QueryLog> object, which is stored in the L<Plack> C<$env> at
C<$env->{'plack.middleware.dbic.querylog'}>.  If you are using L<Catalyst> and
a modern L<Catalyst::Model::DBIC::Schema> you can use the supplied trait
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>, which is 
compatible with L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>.  For
example in you L<Catalyst::Model::DBIC::Schema> model:

    package MyApp::Web::Model::Schema;
    use parent 'Catalyst::Model::DBIC::Schema';

	__PACKAGE__->config({
        schema_class => 'MyApp::Schema',
        traits => ['QueryLog::AdoptPlack'],
		connect_info => {
			dsn => 'dbi:SQLite:dbname=__path_to(share,var,sqlite.db)__',
		},
	});

    1;

=head1 DESCRIPTION

Adds a debug panel and querylog object for logging L<DBIx::Class> queries.  Has
support for L<Catalyst> via a L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>
compatible trait, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>.

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

L<Plack::Middleware::Debug>

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
    $env->{'plack.middleware.dbic.querylog'} = $querylog;
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
