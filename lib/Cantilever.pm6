use v6;

class Cantilever {
  use Web::App;
  use HTTP::Easy::PSGI;

  # Public
  has Bool $.dev = False;
  has Str $.root;
  has Int $.cache_life = 604800; # One week
  has Int $.port = 3000;

  # Private
  has $!app;
  has $!http;
  has $!handler;

  submethod BUILD() {
    $!handler = sub ($context) {
      given $context.path {
        when '/' {
          $context.set-status(200);
          $context.content-type('text/html');
          $context.send("Hello, world!");
        }
      }
    };
  }

  method run() {
    $!http = HTTP::Easy::PSGI.new(debug => $.dev, port => $.port);
    $!app = Web::App.new($!http);
    $!app.run: $!handler;
  }
}
