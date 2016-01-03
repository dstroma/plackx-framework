package PlackX::Framework::Response;
use base 'Plack::Response';

use strict;
use warnings;

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

1;

