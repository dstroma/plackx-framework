use strict;
use warnings;

package PlackX::Framework::Request;
use parent 'Plack::Request';

use constant MAX_REROUTES => 100;
use Try::Tiny;

sub is_request  { 1 }
sub is_response { 0 }
sub is_post     { uc shift->method eq 'POST' }
sub is_get      { uc shift->method eq 'GET'  }
sub is_ajax     { uc shift->header('X-Requested-With') eq uc 'XMLHttpRequest' }

# Override Plack::Request->uri so we can use our subclass of URI::Fast
sub uri {
  my $self = shift;

  # The URI module is optional, so only load it on demand
  require PlackX::Framework::URI;
  my $uri_class = $self->app_class . '::URI';
  $uri_class = 'PlackX::Framework::URI' unless try { require $uri_class; 1 };

  # Copied from uri method of Plack::Request
  my $base = $self->_uri_base;
  my $path_escape_class = q{^/;:@&=A-Za-z0-9\$_.+!*'(),-};
  my $path = URI::Escape::uri_escape($self->env->{PATH_INFO} || '', $path_escape_class);
  $path .= '?' . $self->env->{QUERY_STRING}
      if defined $self->env->{QUERY_STRING} && $self->env->{QUERY_STRING} ne '';
  $base =~ s!/$!! if $path =~ m!^/!;
  # End copy
 
  return $uri_class->new($base . $path)->normalize;
}

sub destination {
  my $self     = shift;
  if ($self->{'plackx.framework.reroutes'}) {
    my $last_i = $#{  $self->{'plackx.framework.reroutes'}  };
    die 'Maximum number of reroutes '.MAX_REROUTES." exceeded. Routes oldest to newest are:\n"
      . join("\n", @{  $self->{'plackx.framework.reroutes'}  })
      . "\n"
      if $last_i > MAX_REROUTES;
    return $self->{'plackx.framework.reroutes'}->[$last_i];
  }
  $self->path_info;
}

sub reroute {
  my $self     = shift;
  my $where_to = shift;
  $self->{'plackx.framework.reroutes'} //= [$self->{'env'}{'PATH_INFO'}];
  push @{  $self->{'plackx.framework.reroutes'}  }, $where_to;
  return $self;
}

sub app_class {
  shift->{app_class};
}

sub set_app_class {
  my $self = shift;
  $self->{app_class} = shift;
}

sub stash {
  shift->{stash};
}

sub set_stash {
  my $self = shift;
  $self->{stash} = shift;
}

sub route_param {
  my $self = shift;
  return $self->{route_parameters}{shift};
}

sub route_parameters {
  my $self = shift;
  $self->{route_parameters};
}

sub set_route_parameters {
  my $self = shift;
  $self->{route_parameters} = shift;
}

1;

