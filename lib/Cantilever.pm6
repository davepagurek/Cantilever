use v6;

use Web::App;
use HTTP::Easy::PSGI;

use Cantilever::Path;
use Cantilever::Category;
use Cantilever::Test::Context;
use Cantilever::Exception;

class Cantilever {
  has Bool $.dev = False;
  has Str $.root = ".";
  has Int $.cache-life = 604800; # One week
  has Int $.port = 3000;
  has Str $.content-dir = "content";
  has @.custom-tags = [];

  has Web::App $!app;
  has HTTP::Easy::PSGI $!http;
  has Cantilever::Category $!pages = Cantilever::Category.new(
    path => $!content-dir.IO,
    root => $!root,
    custom-tags => @!custom-tags
  );

  has &.home is rw = -> $category { "<h1>Home</h1>"; }
  has &.page is rw = -> $page { "<h1>{$page.meta<title> || 'Untitled'}</h1> \n {$page.rendered}"; }
  has &.category is rw = -> $category {
    "<h1>Category {$category.meta<name> || 'Untitled'}</h1> \n" ~
    "<h2>Subcategories</h2> \n <ol>" ~
    $category.sub-cats.kv.map(-> $slug, $cat {
      "<li><a href='$cat.link()'>{$cat.meta<name> || $slug}</a></li>"
    }) ~
    "</ol> \n <h2>Pages</h2> \n <ol>" ~ 
    $category.pages.kv.map(-> $slug, $page {
      "<li><a href='$page.link()'>{$page.meta<title> || $slug}</a></li>"
    }) ~
    "</ol>";
  }
  has &.error is rw = -> $error {
    "<h1>Error {$error.?code || 500}</h1> \n " ~
    "<pre>{$error.perl}</pre> \n " ~
    "<pre>{ do given $error.backtrace[0] { [.file, .line, .subname].join('\n') } }</pre>";
  }

  has &!handler = -> $context {
    my $path = Cantilever::Path.new(
      path => $context.path,
      content-dir => $!content-dir
    );
    my $content = "";
    if $path.is-home {
      $content = &!home($!pages);
    } elsif $path.is-page && my $page = $!pages.get-page($path.page-tree) {
      $content = &!page($page);
    } elsif $path.is-category && my $category = $!pages.get-category($path.page-tree) {
      $content = &!category($category);
    } else {
      die Cantilever::Exception.new(
        code => 404,
        path => $path,
        message => "Couldn't find page $!root/{$path.page-tree.join('/')}"
      );
    }
    $context.set-status(200);
    $context.content-type('text/html');
    $context.send($content);

    CATCH {
      default {
        $context.set-status(.code || 500);
        $context.content-type('text/html');
        $context.send(&!error($_));
      }
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
