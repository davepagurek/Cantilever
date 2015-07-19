use v6;

use Web::App;
use HTTP::Easy::PSGI;

use Cantilever::Path;

class Cantilever {
  has Bool $.dev = False;
  has Str $.root;
  has Int $.cache-life = 604800; # One week
  has Int $.port = 3000;
  has Str $.content-dir = "content";

  has $!app;
  has $!http;
  has $!handler;

  method !make-handler {
    $!handler = sub ($context) {
      my $path = Cantilever::Path.new(
        path => $context.path,
        content-dir => $.content-dir,
      );
      if $path.is-home {
        $context.set-status(200);
        $context.content-type('text/html');
        $context.send("Home");
      } elsif $path.is-page {
        $context.set-status(200);
        $context.content-type('text/html');
        $context.send("Page: $path.category/$path.page");
      } elsif $path.is-category {
        $context.set-status(200);
        $context.content-type('text/html');
        $context.send("Category: $path<category>");
      } else {
        $context.set-status(404);
        $context.content-type('text/html');
        $context.send("Page not found!");
      }
    }
  }

  method run {
    $!http = HTTP::Easy::PSGI.new(debug => $.dev, port => $.port);
    $!app = Web::App.new($!http);
    self!make-handler;
    $!app.run: $!handler;
  }
}
