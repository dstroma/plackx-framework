use v5.40;
package PlackX::Framework::Response {
  use parent 'Plack::Response';
  use JSON::MaybeXS qw(encode_json decode_json);

  # Simple accessors
  use Plack::Util::Accessor qw(app_namespace stash cleanup_callbacks template);

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
    my $max_age = $value ? 300 : -1; # If value is false we delete the cookie
    $self->cookies->{flash_cookie_name($self)} = { value=>$value, path=>'/', 'max-age'=>$max_age };
    return $self;
  }

  sub render_json ($self, $data) { $self->render_content('application/json', encode_json($data)) }
  sub render_text ($self, $text) { $self->render_content('text/plain',       $text             ) }
  sub render_html ($self, $html) { $self->render_content('text/html',        $html             ) }
  sub render_template ($self)    { $self->{template}->render; $self }
  sub render_content ($self, $content_type, $body) {
    $self->status(200);
    $self->content_type($content_type);
    $self->body($body);
    return $self;
  }
}
