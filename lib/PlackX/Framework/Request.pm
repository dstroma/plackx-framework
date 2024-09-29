use v5.40;
package PlackX::Framework::Request {
  use parent 'Plack::Request';
  use Carp qw(croak);

  sub max_reroutes { 100 }
  sub is_request   {   1 }
  sub is_response  {   0 }
  sub is_get       { uc shift->method eq 'GET'    }
  sub is_post      { uc shift->method eq 'POST'   }
  sub is_put       { uc shift->method eq 'PUT'    }
  sub is_delete    { uc shift->method eq 'DELETE' }
  sub is_ajax      { uc (shift->header('X-Requested-With') || '') eq 'XMLHTTPREQUEST' }
  sub url_crypt    { my $h = crypt(shift, shift); $h =~ tr`/.`-_`; $h }

  sub destination ($self)                { $self->{destination} || $self->path_info    }
  sub app_class ($self)                  { $self->{app_class}                          }
  sub set_app_class ($self, $new)        { $self->{app_class} = $new                   }
  sub stash ($self)                      { $self->{stash}                              }
  sub set_stash ($self, $stash)          { $self->{stash} = $stash                     }
  sub route_param ($self, $name)         { $self->{route_parameters}{$name}            }
  sub route_parameters ($self)           { $self->{route_parameters}                   }
  sub set_route_parameters ($self, $new) { $self->{route_parameters} = $new            }
  sub flash_cookie_name ($self)          { 'flash' . url_crypt($self->app_class, '--') }
  sub flash ($self)                      { $self->cookies->{$self->flash_cookie_name}  }

  sub urix ($self) {
    # The URI module is optional, so only load it on demand
    require PlackX::Framework::URIx;
    my $urix_class = $self->app_class . '::URIx';
    $urix_class = 'PlackX::Framework::URIx' unless eval "require $urix_class; 1";

    # Copied from uri method of Plack::Request
    my $base = $self->_uri_base;
    my $path_escape_class = q{^/;:@&=A-Za-z0-9\$_.+!*'(),-};
    my $path = URI::Escape::uri_escape($self->env->{PATH_INFO} || '', $path_escape_class);
    $path .= '?' . $self->env->{QUERY_STRING}
      if defined $self->env->{QUERY_STRING} && $self->env->{QUERY_STRING} ne '';
    $base =~ s!/$!! if $path =~ m!^/!;

    return $urix_class->new($base . $path)->normalize;
  }

  sub reroute ($self, $dest) {
    $self->{'pxf'}{'reroutes'} //= [$self->path_info];
    push $self->{'pxf'}{'reroutes'}->@*, $dest;

    # Protect against recursive reroutes
    my $max_reroutes = $self->max_reroutes;
    if (scalar $self->{'pxf'}{'reroutes'}->@* > $max_reroutes) {
      my $routelist_string = join("\n", $self->{'pxf'}{'reroutes'}->@*);
      croak "Maximum of $max_reroutes reroutes exceeded. Oldest to newest:\n$routelist_string\n";
    }

    $self->{destination} = $dest;
    return $self;
  }
}
