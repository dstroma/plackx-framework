use v5.40;
package PlackX::Framework::Config {
  use Config::Any;

  sub import ($class, @options) {
    my $caller = caller(0);
    my $file   = shift @options || $ENV{uc $class . '_CONFIG'};
    my $config = eval {
      Config::Any->load_files({
        files   => [$file],
        use_ext => 1,
      })->[0]->{$file}
    } or die "Unable to load config file $file via Config::Any:\n$@";

    my $config_sub = sub { $config };
    { no strict 'refs';
      *{$caller.'::config'}         = $config_sub;
      *{$caller.'::Config::config'} = $config_sub;
    }
  }
}

=pod

Usage Example:

  package My::WebApp {
    use PlackX::Framework qw(:config);
    use My::WebApp::Config '/path/to/config_file';

    my $value = config->{key}{subkey};

    # May also be written as:
    #   My::WebApp->config
    #   My::WebApp::config()
    #   My::WebApp::Config->config
    #   My::WebApp::Config::config()
  }

This module is offered as a convenience to the user, and is not used to
configure PlackX::Framework directly.
