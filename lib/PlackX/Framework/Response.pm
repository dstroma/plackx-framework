use v5.40;
package PlackX::Framework::Response {
  use parent 'Plack::Response';

  # Simple accessors
  use Plack::Util::Accessor qw(stash cleanup_callbacks template);

  sub is_request        { 0     }
  sub is_response       { 1     }
  sub continue          { undef }
  sub stop              { $_[0] }
  sub flash_cookie_name { PlackX::Framework::Request::flash_cookie_name(shift) }
  sub print ($self, @lines)              { push @{$self->{body}}, @lines; $self     }
  sub redirect ($self, @args)            { $self->SUPER::redirect(@args);  $self    }
  sub add_cleanup_callback ($self, $sub) { push @{$self->{cleanup_callbacks}}, $sub }

  sub new ($class, @args) {
    my $self = $class->SUPER::new(@args);
    $self->{cleanup_callbacks} //= [];
    $self->{body}              //= [];
    return bless $self, $class;
  }

  sub no_cache ($self, $bool) {
    my $val = $bool ? 'no-cache' : undef;
    $self->header('Pragma' => $val, 'Cache-control' => $val);
  }

  sub flash ($self, $value //= '') {
    # Values are automatically encoded by Cookie::Baker
    my $max_age = $value ? 300 : -1; # If value is false we delete the cookie
    $self->cookies->{flash_cookie_name($self)} = { value=>$value, path=>'/', 'max-age'=>$max_age };
    return $self;
  }

  sub flash_redirect ($self, $flashval, $url) {
    return $self->flash($flashval)->redirect($url, 303);
  }

  sub render_json ($self, $data)     { $self->render_content('application/json', encode_json($data)) }
  sub render_text ($self, $text)     { $self->render_content('text/plain',       $text             ) }
  sub render_html ($self, $html)     { $self->render_content('text/html',        $html             ) }
  sub render_template ($self, @args) { $self->{template}->render(@args); $self }

  sub render_content ($self, $content_type, $body) {
    $self->status(200);
    $self->content_type($content_type);
    $self->body($body);
    return $self;
  }

  sub encode_json ($data) {
    require JSON::MaybeXS;
    state $json = JSON::MaybeXS->new(utf8 => 1);
    return $json->encode($data);
  }

  sub GlobalResponse ($class, @args) {
    $class = ref $class if ref $class;
    state $response_objects = {};
    $response_objects->{$class} = shift @args if @args;
    $response_objects->{$class};
  }
}
