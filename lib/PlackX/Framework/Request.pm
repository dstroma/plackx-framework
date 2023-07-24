use 5.10.0;
use strict;
use warnings;

package PlackX::Framework::Request;
use parent 'Plack::Request';
use Try::Tiny;
use Carp qw(croak);
use Digest::MD5 qw(md5_base64);

sub max_reroutes { 100 }
sub is_request   {   1 }
sub is_response  {   0 }
sub is_get       { uc shift->method eq 'GET'    }
sub is_post      { uc shift->method eq 'POST'   }
sub is_put       { uc shift->method eq 'PUT'    }
sub is_delete    { uc shift->method eq 'DELETE' }
sub is_ajax      { uc shift->header('X-Requested-With') eq 'XMLHTTPREQUEST' }

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
  my $self = shift;
  $self->{destination} || $self->path_info;
}

sub reroute {
  my $self = shift;
  my $dest = shift;
  $self->{'plackx.framework.reroute_count'} ||= 0;
  $self->{'plackx.framework.reroute_count'}  += 1;
  $self->{'plackx.framework.reroutes'}      //= [$self->path_info];
  push @{  $self->{'plackx.framework.reroutes'}  }, $dest;

  # Protect against recusrive reroutes
  my $max_reroutes = $self->max_reroutes;
  if ($self->{'plackx.framework.reroute_count'} > $max_reroutes) {
    croak "Maximum number of reroutes $max_reroutes exceeded. Routes oldest to newest are:\n"
    . join("\n", @{  $self->{'plackx.framework.reroutes'}  })
    . "\n";
  }

  $self->{destination} = $dest;
  return $self;
}

sub app_class {
  my $self = shift;
  $self->{app_class};
}

sub set_app_class {
  my $self = shift;
  my $new  = shift;
  $self->{app_class} = $new;
}

sub stash {
  my $self = shift;
  $self->{stash};
}

sub set_stash {
  my $self  = shift;
  my $stash = shift;
  $self->{stash} = $stash;
}

sub route_param {
  my $self = shift;
  my $name = shift;
  return $self->{route_parameters}{$name};
}

sub route_parameters {
  my $self = shift;
  $self->{route_parameters};
}

sub set_route_parameters {
  my $self = shift;
  my $new  = shift;
  $self->{route_parameters} = $new;
}

sub flash {
  my $self   = shift;
  my $cname  = 'flash' . md5_base64($self->app_class);
  $self->cookies->{$cname};
}

1;

