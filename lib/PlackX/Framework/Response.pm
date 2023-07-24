use v5.10;
use strict;
use warnings;

package PlackX::Framework::Response;
use parent 'Plack::Response';
use Digest::MD5 qw(md5_base64);

sub is_request  { 0 }
sub is_response { 1 }
sub continue    { return; }
sub stop        { $_[0]   }

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  $self->{_no_cache}                = 0;
  $self->{_body}                    = [];
  $self->{_post_response_callbacks} = [];
  $self->{_size}                    = 0;

  $self->body($self->{_body});
  $self->{_size} += length($_) for @{$self->{_body}};

  return bless $self, $class;
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

sub no_cache {
  my $self = shift;
  if (@_ > 0) {
    my $setting = shift;
    if ($setting) {
      $self->header('Pragma' => 'no-cache');
      $self->header('Cache-control' => 'no-cache');
      $self->{_no_cache} = 1;
    } else {
      $self->header('Pragma' => undef);
      $self->header('Cache-control' => undef);
      $self->{_no_cache} = 0;
    }
  }
  return $self->{_no_cache};
}

sub print {
  # Adds a line or lines to the body string
  my $self = shift;
  $self->{_size} ||= 0;
  $self->{_size}  += (length($_) || 0) for @_;
  push @{$self->{_body}}, @_;
  return $self;
}

sub size {
  my $self = shift;
  return $self->{_size};
}

sub add_post_response_callback {
  my $self = shift;
  my $code = shift;
  push @{$self->{_post_response_callbacks}}, $code;
}

sub post_response_callbacks {
  my $self = shift;
  return $self->{_post_response_callbacks};
}

sub stash {
  my $self = shift;
  return $self->{stash};
}

sub set_stash {
  my $self = shift;
  my $hash = shift;
  $self->{stash} = $hash;
}

sub flash {
  my $self    = shift;
  my $value   = shift;
  my $max_age = $value ? 120 : -1; # If value is false we delete the cookie
  my $cname   = 'flash' . md5_base64($self->app_class);
  $self->cookies->{$cname} = { value => $value, path => '/', 'max-age' => $max_age };
  return $self;
}

sub template {
  my $self = shift;
  $self->{_template} = shift if @_;
  die "No template module loaded" if !$self->{_template};
  return $self->{_template};
}

1;

