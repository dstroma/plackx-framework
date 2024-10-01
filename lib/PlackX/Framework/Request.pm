use v5.40;
package PlackX::Framework::Request {
  use parent 'Plack::Request';
  use Carp qw(croak);

  # Simple accessors
  use Plack::Util::Accessor qw(
    app_namespace stash cleanup_callbacks template route_parameters
  );

  sub max_reroutes  { 16 }
  sub is_request    {  1 }
  sub is_response   {  0 }
  sub is_get        { uc shift->method eq 'GET'    }
  sub is_post       { uc shift->method eq 'POST'   }
  sub is_put        { uc shift->method eq 'PUT'    }
  sub is_delete     { uc shift->method eq 'DELETE' }
  sub is_ajax       { uc (shift->header('X-Requested-With') || '') eq 'XMLHTTPREQUEST' }
  sub destination ($self)                { $self->{pxf}{dest} // $self->path_info      }
  sub route_param ($self, $name)         { $self->{route_parameters}{$name}            }
  sub flash_cookie_name ($self)          { 'flash' . url_crypt($self->app_class, '--') }
  sub flash ($self)                      { $self->cookies->{$self->flash_cookie_name}  }
  sub url_crypt ($d, $s)                 { my $h = crypt($d, $s); $h =~ tr`./`-_`; $h  }

  sub reroute ($self, $dest) {
    my $routelist = $self->{pxf}{reroutes} //= [$self->path_info];
    push @$routelist, ($self->{pxf}{dest} = $dest);

    croak "Maximum reroutes exceeded:\n".join("\n", @$routelist)
      if @$routelist > $self->max_reroutes;

    return $self;
  }

  sub urix ($self) {
    # The URI module is optional, so only load it on demand
    require PlackX::Framework::URIx;
    my $urix_class = $self->app_class . '::URIx';
    $urix_class = 'PlackX::Framework::URIx' unless eval "require $urix_class; 1";
    $urix_class->new_from_request($self);
  }
}
