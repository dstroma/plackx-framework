use v5.38;
use experimental qw(class try);

class PlackX::Framework::Template {

  field $response :param;
  field $engine :param = undef;
  field $template; 
  field $params = {};

  # We store an engine object for each subclass (override by supplying an engine in ->new())
  my %engine_registry = ();

  ###
  ### Import
  ###

  sub import ($class, $options) {
    # Trap errors
    die "Import from your app's sublcass of PlackX::Framework::Template, not directly"
      if $class eq __PACKAGE__;

    # Do nothing if get_template_system_object returns something
    return if $engine_registry{$class};

    # By default, setup Template Toolkit
    my $engine;
    my %engine_options = ref $options ? %$options : ();
    $engine_options{'INCLUDE_PATH'} = 'template' unless exists $engine_options{'INCLUDE_PATH'};

    try {
      require Template;
      $engine_registry{$class} = Template->new(\%engine_options);
    } catch ($err) {
      warn "Tried to 'require Template' (Template Toolkit) but failed: $err\n";
    }

    return;
  }

  ###
  ### Methods
  ###

  method get_engine () {
    my $for_class = ref $self;
    $engine ||= $engine_registry{$for_class};
    $engine || warn "No template engine has been defined for $for_class.\n";
    $engine
  }

  method set_engine ($new_engine) {
    $engine = $new_engine;
  }

  # Get or set a single param
  method param ($name, @splat) {
    $params->{$name} = shift @splat if @splat;
    $params->{$name};
  }

  # Set one or many params
  method add_params (%new_params) {
    @{$params}{keys %new_params} = values %new_params;
    $self;
  }

  # Same as above
  method set (%new_params) {
    @{$params}{keys %new_params} = values %new_params;
    $self;
  }

  # Name a template file or template content
  method use ($new_template) {
    $template = $new_template;
    $self;
  }

  method output ($new_template = undef) {
    $template = $new_template // $template;
    $self->get_engine->process($template, $params, $response);
  }

  method render {
    $self->output(@_);
    $response;
  }
}

