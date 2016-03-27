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
  has @.ignore = [];
  has @.custom-tags = [];

  has Web::App $!app;
  has HTTP::Easy::PSGI $!http;
  has Cantilever::Category $!pages = Cantilever::Category.new(
    path => $!content-dir.IO,
    root => $!root,
    custom-tags => @!custom-tags,
    ignore => @!ignore,
    dev => $!dev
  );

  has &.home is rw = -> %params { "<h1>Home</h1>"; }
  has &.page is rw = -> %params { "<h1>{%params<page>.meta<title> || 'Untitled'}</h1> \n {%params<page>.rendered}"; }
  has &.category is rw = -> %params {
    "<h1>Category {%params<category>.meta<name> || 'Untitled'}</h1> \n" ~
    "<h2>Subcategories</h2> \n <ol>" ~
    %params<category>.sub-cats.kv.map(-> $slug, $cat {
      "<li><a href='$cat.link()'>{$cat.meta<name> || $slug}</a></li>"
    }) ~
    "</ol> \n <h2>Pages</h2> \n <ol>" ~ 
    %params<category>.pages.kv.map(-> $slug, $page {
      "<li><a href='$page.link()'>{$page.meta<title> || $slug}</a></li>"
    }) ~
    "</ol>";
  }
  has &.error is rw = -> %params {
    "<h1>Error {%params<error>.?code || 500}</h1> \n " ~
    "<pre>{%params<error>.perl}</pre> \n " ~
    "<pre>{ do given %params<error>.backtrace[0] { [.file, .line, .subname].join('\n') } }</pre>";
  }

  has &!handler = -> $context {
    my $path = Cantilever::Path.new(
      path => $context.path,
      content-dir => $!content-dir
    );
    my $content = "";
    if $path.is-home {
      $content = &!home({
        type => "home",
        content => $!pages,
        root => $!root
      });
    } elsif $path.is-page && my $page = $!pages.get-page($path.page-tree) {
      $content = &!page({
        type => "page",
        content => $!pages,
        root => $!root,
        page => $page
      });
    } elsif $path.is-category && my $category = $!pages.get-category($path.page-tree) {
      $content = &!category({
        type => "category",
        content => $!pages,
        root => $!root,
        category => $category
      });
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
        my $err = $_;
        $err.say;
        $context.set-status($err.code || 500);
        $context.content-type('text/html');
        $context.send(&!error({
          type => "error",
          content => $!pages,
          root => $!root,
          error => $err
        }));
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
