use v5.40;
package PlackX::Framework::Template {
  my %template_engine_objects = ();

  sub import ($class, $options = {}) {
    die "Import from your app's sublcass of PlackX::Framework::Template, not directly"
      if $class eq __PACKAGE__;

    # Do nothing if get_template_system_object returns something
    return if $class->get_template_engine;

    # Setup Template Toolkit if available
    try {
      require Template;
      $options->{'INCLUDE_PATH'} //= 'template';
      $class->set_template_engine(Template->new($options));
    } catch ($e) {
      warn "Unable to load Template Toolkit: $e";
    }
  }

  sub new ($class, $response, $templater = undef) {
    die 'Usage: ->new($response_object)' unless $response and ref $response;

    $templater = $class->get_template_engine() unless $templater;
    die 'Not a valid template engine object'   unless $templater and ref $templater;

    return bless {
      template_engine_object => $templater,
      response_object => $response,
      params => {},
    }, $class;
  }

  sub self_to_class ($self)             { ref $self ? ref $self : $self }
  sub get_template_engine ($self)       { $template_engine_objects{ref $self ? ref $self : $self} }
  sub set_template_engine ($self, $new) { $template_engine_objects{self_to_class $self} = $new }
  sub set_filename ($self, $fname)      { $self->{filename} = $fname }
  sub param ($self, $name)              { $self->{params}{$name}     }
  sub add_params ($self, %params)       { @{$self->{params}}{keys %params} = values %params; $self }
  sub render ($self, @args)             { $self->output(@args); $self->{response_object} }
  *set = \&add_params;
  *use = \&set_filename;

  sub output ($self, $filename = undef) {
    # If using a non-TT compatible engine, override output() in your subclass
    $filename //= $self->{filename};
    my $engine  = $self->{template_engine_object};
    $engine->process($filename, $self->{params}, $self->{response_object}) || die 'Unable to process template: ', $engine->error, $!;
  }
}

=pod

=head1 NAME

PlackX::Framework::Template - Use templates in a PlackX::Framework app.


=head1 SYNOPSIS

This module allows a convenient way to select template files, add parameters,
process, and output them. By default, Template Toolkit ('Template') is used,
but you can specify your own.

Your PlackX::Framework app will automatically create a new instance of this
class and make it available to your $response object.

    # In your controller
    my $template = $response->template;
    $template->set_filename('foobar.tmpl'); # or ->use('foobar.tmpl');
    $template->add_params(building => 'house', color => 'orange'); # or ->set(...)
    return $template->render;


=head1 CUSTOM TEMPLATE ENGINE

To use your own, override the get_template_engine() method to return an
instance of your templating engine object. If your engine does not have a
Template-Toolkit-compatible process() method, you will have to override
the output() method of this module as well.

For example:

    package MyApp::Template {
      my $te = Some::Template::Engine->new;
      sub get_template_engine { $te; }
      sub output ($self, $file) {
        $self->get_template_engine->render($file, $self->{'params'}->%*);
      }
    }
