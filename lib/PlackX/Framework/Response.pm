use v5.40;
package PlackX::Framework::Response {
  use parent 'Plack::Response';
  use JSON::MaybeXS qw(encode_json decode_json);

  sub new ($class, @args) {
    my $self = $class->SUPER::new(@args);
    $self->{pxf} = { cleanup_callbacks => [] };
    return bless $self, $class;
  }

  sub is_request        {   0   }
  sub is_response       {   1   }
  sub continue          { undef }
  sub stop ($self)      { $self }
  sub flash_cookie_name ($self) { PlackX::Framework::Request::flash_cookie_name($self) }
  sub app_class ($self)                  { $self->{pxf}{app_class}               }
  sub set_app_class ($self, $value)      { $self->{pxf}{app_class} = $value      }
  sub stash ($self)                      { $self->{pxf}{stash}                   }
  sub set_stash ($self, $value)          { $self->{pxf}{stash} = $value          }
  sub print ($self, @lines)              { push @{$self->body}, @lines; $self    }
  sub redirect ($self, @args)            { $self->SUPER::redirect(@args);  $self }
  sub cleanup_callbacks ($self)          { $self->{pxf}{cleanup_callbacks}       }
  sub add_cleanup_callback ($self, $sub) { push @{$self->{pxf}{cleanup_callbacks}}, $sub }

  sub no_cache ($self, $bool) {
    my $val = $bool ? 'no-cache' : undef;
    $self->header('Pragma' => $val, 'Cache-control' => $val);
  }

  sub flash ($self, $value //= '') {
    my $max_age = $value ? 120 : -1; # If value is false we delete the cookie
    $self->cookies->{flash_cookie_name($self)} = { value=>$value, path=>'/', 'max-age'=>$max_age };
    return $self;
  }

  sub template ($self, @args) {
    $self->{pxf}{template} = shift @args if @args;
    return $self->{pxf}{template} || die 'No template object';
  }

  sub render_json ($self, $data) { $self->render_content('application/json', encode_json($data)) }
  sub render_text ($self, $text) { $self->render_content('text/plain',       $text             ) }
  sub render_html ($self, $html) { $self->render_content('text/html',        $html             ) }
  sub render_template ($self)    { $self->{pxf}{template}->render; $self                         }
  sub render_content ($self, $content_type, $body) {
    $self->status(200);
    $self->content_type($content_type);
    $self->body($body);
    return $self;
  }
}
