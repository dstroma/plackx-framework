use v5.40;
package PlackX::Framework::Handler {
  use Scalar::Util qw(blessed);
  use Module::Loaded qw(is_loaded);

  # Public class methods
  sub to_app ($class, %options)  {
    my $serve_static_files = delete $options{'serve_static_files'};
    my $static_docroot     = delete $options{'static_docroot'};
    die "Unknown options: " . join(', ', keys %options) if %options;

    if ($serve_static_files) {
      require Plack::App::File;
      my $static_app = Plack::App::File->new(root => $static_docroot)->to_app;
      return sub ($env) {
        my $resp = $class->handle_request($env);
        return $resp if $resp and $resp->[0] != 404;
        return $static_app->($env);
      };
    } else {
      return sub ($env) {
        return $class->handle_request($env);
      };
    }
  }

  sub not_found_response { [404, [], ['Not Found']]              }
  sub error_response     { [500, [], ['Internal Server Error']]  }

  sub handle_request ($class, $env_or_req, $maybe_resp = undef) {
    my $app_namespace = $class->app_namespace;

    # Get or create request and response objects
    my $env      = $class->env_or_req_to_env($env_or_req);
    my $request  = $class->env_or_req_to_req($env_or_req);
    my $response = $maybe_resp || ($app_namespace . '::Response')->new(200);

    # Set up stash
    my $stash = ($request->stash or $response->stash or {});
    $request->stash($stash);
    $response->stash($stash);

    # Maybe set up Templating, if loaded
    if (is_loaded($app_namespace . '::Template')) {
      try {
        my $template = ($app_namespace . '::Template')->new($response);
        $template->set(REQUEST => $request, RESPONSE => $response);
        $response->template($template);
      } catch ($e) {
        warn "Unable to set up template: $e";
      }
    }

    # Clear flash if set, set response defaults
    $response->flash(undef);
    $response->content_type('text/html');

    return $class->route_request($request, $response);
  }

  sub route_request ($class, $request, $response) {
    my $result = check_request_prefix($class->app_namespace, $request);
    return $result if $result;

    my $rt_engine = ($class->app_namespace . '::Router::Engine')->instance;
    if (my $match = $rt_engine->match($request)) {
      $request->route_parameters($match);

      # Execute prefilters
      my $prefilter_result = execute_filters($match->{prefilters}, $request, $response);
      return finalized_response($prefilter_result) if $prefilter_result and is_valid_response($prefilter_result);

      # Execute main action
      my $result = $match->{action}->($request, $response);
      unless ($result and ref $result) {
        warn "PlackX::Framework - Invalid result\n";
        return $class->error_response;
      }

      # Check if the "response" is actually another "request" (despite the variable name)
      return $class->handle_request($result) if $result->is_request;
      return $class->error_response unless $result->is_response;
      $response = $result;

      # Execute postfilters
      my $postfilter_result = execute_filters($match->{postfilters}, $request, $response);
      return finalized_response($postfilter_result) if $postfilter_result and is_valid_response($postfilter_result);

      # Clean up (does server support cleanup handlers? Add to list or else execute now)
      if ($response->cleanup_callbacks and scalar $response->cleanup_callbacks->@* > 0) {
        if ($request->env->{'psgix.cleanup'}) {
          push $request->env->{'psgix.cleanup.handlers'}->@*, $response->cleanup_callbacks->@*;
        } else {
          $_->($request->env) for $response->cleanup_callbacks->@*;
        }
      }

      return finalized_response($response) if is_valid_response($response);
    }

    return $class->not_found_response;
  }

  # Helpers ###################################################################

  sub check_request_prefix ($class, $request) {
    if ($class->can('uri_prefix') and my $prefix = $class->uri_prefix) {
      if (substr($request->destination, 0, length $prefix) eq $prefix) {
        $request->{destination} = substr($request->destination, length $prefix);
        return;
      }
      return not_found_response();
    }
    return;
  }

  sub execute_filters ($filters, $request, $response) {
    return unless $filters and ref $filters eq 'ARRAY';
    foreach my $filter (@$filters) {
      my $response = $filter->{action}->($request, $response, @{$filter->{params}});
      return $response if $response and is_valid_response($response);
    }
    return;
  }

  sub is_valid_response {
    my $response = pop;
    return undef unless defined $response and ref $response;      # Bad  - must be defined and be a ref
    return 1 if ref $response eq 'ARRAY' and @$response == 3;     # Good - PSGI raw response arrayref
    return 1 if blessed $response and $response->can('finalize'); # Good - Plack-like response object with finalize() method
    return undef;
  }

  sub finalized_response {
    my $response = pop;
    return ref $response eq 'ARRAY' ? $response : $response->finalize;
  }

  sub env_or_req_to_req ($class, $env_or_req) {
    if (ref $env_or_req and ref $env_or_req eq 'HASH') {
      return ($class->app_namespace . '::Request')->new($env_or_req);
    } elsif (blessed $env_or_req and $env_or_req->isa('PlackX::Framework::Request')) {
      return $env_or_req;
    }
    die 'Neither a PSGI-type HASH reference nor a PlackX::Framework::Request object.';
  }

  sub env_or_req_to_env ($class, $env_or_req) {
    if (ref $env_or_req and ref $env_or_req eq 'HASH') {
      return $env_or_req;
    } elsif (blessed $env_or_req and $env_or_req->isa('PlackX::Framework::Request')) {
      return $env_or_req->env;
    }
    die 'Neither a PSGI-type HASH reference nor a PlackX::Framework::Request object.';
  }
}
