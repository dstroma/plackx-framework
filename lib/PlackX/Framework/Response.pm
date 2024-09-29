use v5.40;
package PlackX::Framework::Response {
  use parent 'Plack::Response';
  use JSON::MaybeXS qw(encode_json decode_json);
  *flash_cookie_name = \&PlackX::Framework::Request::flash_cookie_name;

  sub new ($class, @args) {
    my $self = $class->SUPER::new(@args);
    $self->{pxf} = { cleanup_callbacks => [], no_cache = undef };
    return bless $self, $class;
  }

  sub is_request   {   0   }
  sub is_response  {   1   }
  sub continue     { undef }
  sub stop ($self) { $self }
  sub app_class ($self)                   { $self->{pxf}{app_class}               }
  sub set_app_class ($self, $value)       { $self->{pxf}{app_class} = $value      }
  sub stash ($self)                       { $self->{pxf}{stash}                   }
  sub set_stash ($self, $value)           { $self->{pxf}{stash} = $value          }
  sub print ($self, @lines)               { push @{$self->body}, @lines; $self    }
  sub redirect ($self, @args)             { $self->SUPER::redirect(@args);  $self }
  sub cleanup_callbacks ($self)           { $self->{pxf}{cleanup_callbacks}       }
  sub add_cleanup_callback ($self, $code) { push @{$self->{pxf}{cleanup_callbacks}}, $code }

  sub no_cache ($self, @args) {
    if (@args > 0) {
      my $val = $self->{pxf}{no_cache} = $args[0] ? 'no-cache' : undef;
      $self->header('Pragma' => $val, 'Cache-control' => $val);
    }
    return $self->{pxf}{no_cache};
  }

  sub flash ($self, $value //= '') {
    my $max_age = $value ? 120 : -1; # If value is false we delete the cookie
    $self->cookies->{flash_cookie_name($self)} = { value => $value, path => '/', 'max-age' => $max_age };
    return $self;
  }

  sub template ($self, @args) {
    $self->{pxf}{template} = shift @args if @args;
    die "No template module loaded" if !$self->{pxf}{template};
    return $self->{pxf}{template};
  }

  sub render_template ($self)    { $self->{_template}->render }
  sub render_json ($self, $data) { $self->render_list(200, 'application/json', encode_json($data)) }
  sub render_text ($self, $text) { $self->render_list(200, 'text/plain',       $text             ) }

  sub render_list ($self, $status, $content_type, $body) {
    $self->status($status);
    $self->content_type($content_type);
    $self->body($body);
    return $self;
  }
}
