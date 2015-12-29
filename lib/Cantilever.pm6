use v6;

use Web::App;
use HTTP::Easy::PSGI;

use Cantilever::Path;
use Cantilever::Category;
use Cantilever::Test::Context;

class Cantilever {
  has Bool $.dev = False;
  has Str $.root;
  has Int $.cache-life = 604800; # One week
  has Int $.port = 3000;
  has Str $.content-dir = "content";
  has List @.custom-tags = [];

  has Web::App $!app;
  has HTTP::Easy::PSGI $!http;
  has Cantilever::Category $!pages = Cantilever::Category.new(
    path => $!content-dir.IO,
    root => $!root
  );

  has &!handler = -> $context {
    my $path = Cantilever::Path.new(
      path => $context.path,
      content-dir => $!content-dir
    );
    if $path.is-home {
      $context.set-status(200);
      $context.content-type('text/html');
      $context.send("Home");
    } elsif $path.is-page && $!pages.get-page($path.page-tree) {
      $context.set-status(200);
      $context.content-type('text/html');
      $context.send("Page: $path.source-file()");
    } elsif $path.is-category && $!pages.get-category($path.page-tree) {
      $context.set-status(200);
      $context.content-type('text/html');
      $context.send("Category: $path.source-dir()");
    } else {
      $context.set-status(404);
      $context.content-type('text/html');
      $context.send("Page not found!");
    }
  };

  method run {
    $!http = HTTP::Easy::PSGI.new(debug => $.dev, port => $.port);
    $!app = Web::App.new($!http);
    $!app.run: &!handler;
  }

  method get($url) {
    my $context = Cantilever::Test::Context.new(path => $url);
    &!handler($context);
    return $context.to-hash;
  }
}
