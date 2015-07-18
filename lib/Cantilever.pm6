use v6;

use Web::App;
use HTTP::Easy::PSGI;

use Cantilever::Path;

class Cantilever {

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
      my $path = Cantilever::Path.parse($context.path);
      if $path<home> {
        $context.set-status(200);
        $context.content-type('text/html');
        $context.send("Home");
      if $path<page> {
        $context.set-status(200);
        $context.content-type('text/html');
        $context.send("Page: $path<category>/$path<page>");
      } elsif $path<category> {
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

  method run() {
    $!http = HTTP::Easy::PSGI.new(debug => $.dev, port => $.port);
    $!app = Web::App.new($!http);
    $!app.run: $!handler;
  }
}
