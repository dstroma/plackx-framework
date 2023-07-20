use v5.10;
use strict;
use warnings;

package PlackX::Framework::Response;
use parent 'Plack::Response';

sub is_request  { 0 }
sub is_response { 1 }

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

sub continue { return;       }
sub stop     { return $_[0]; }

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
  $self->{_size} += length($_) for @_;
  push @{$self->{_body}}, @_;
  return $self;
}

sub size {
  my $self = shift;
  return $self->{_size};
}

sub add_post_response_callback {
  # Todo:: Check for mod_perl and add a perlcleanuphandler if mod_perl is present
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
  return undef unless $self->{stash} and ref $self->{stash};
  return $self->{stash};
}

sub set_stash {
  my $self = shift;
  my $hash = shift;
  $self->{stash} = $hash;
}

sub template {
  my $self = shift;
  if (@_) {
    $self->{_template} = shift;
  }
  if (!$self->{_template}) {
    die "No template module loaded";
  }
  return $self->{_template};
}

1;

