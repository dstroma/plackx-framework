use v5.40;
package PlackX::Framework::Config {
  use Config::Any;

  sub import ($class, @options) {
    my $caller = caller(0);
    my $file   = shift @options;
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
  }
