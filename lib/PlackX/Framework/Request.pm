use v5.40;
package PlackX::Framework::Request {
  use parent 'Plack::Request';
  use Carp qw(croak);
  use Module::Loaded qw(is_loaded);

  # Simple accessors
  use Plack::Util::Accessor qw(stash route_parameters);

  sub max_reroutes      { 16 }
  sub is_request        { 1 }
  sub is_response       { 0 }
  sub is_get    ($self) { uc $self->method eq 'GET'    }
  sub is_post   ($self) { uc $self->method eq 'POST'   }
  sub is_put    ($self) { uc $self->method eq 'PUT'    }
  sub is_delete ($self) { uc $self->method eq 'DELETE' }
  sub is_ajax   ($self) { uc($self->header('X-Requested-With') || '') eq 'XMLHTTPREQUEST' }
  sub destination ($self)        { $self->{destination} // $self->path_info        }
  sub sparam ($self, $key)       { scalar $self->parameters->{$key}                }
  sub route_param ($self, $name) { $self->{route_parameters}{$name}                }
  sub flash_cookie_name ($self)  { 'flash' . url_crypt($self->app_namespace, '--') }
  sub flash ($self)              { $self->cookies->{$self->flash_cookie_name}      }
  sub url_crypt ($d, $s)         { my $h = crypt($d, $s); $h =~ tr`./`-_`; $h      }

  sub reroute ($self, $dest) {
    my $routelist = $self->{reroutes} //= [$self->path_info];
    push @$routelist, ($self->{destination} = $dest);
    croak "Excessive reroutes:\n" . join("\n", @$routelist) if @$routelist > $self->max_reroutes;
    return $self;
  }

  sub urix ($self) {
    # The URI module is optional, so only load it on demand
    require PlackX::Framework::URIx;
    my $urix_class = $self->app_namespace . '::URIx';
    $urix_class = 'PlackX::Framework::URIx' unless is_loaded($urix_class) or eval "require $urix_class; 1";
    return $urix_class->new_from_request($self);
  }

  sub INIT_REQUEST ($class, @args) {
    state $r;
    $r = shift @args if @args;
    return $r;
  }
}
