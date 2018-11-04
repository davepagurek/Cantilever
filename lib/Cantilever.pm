use v6;

use Web::App;
use HTTP::Easy::PSGI;

use Cantilever::Path;
use Cantilever::Category;
use Cantilever::Test::Context;
use Cantilever::Exception;
use Shell::Command;

class Cantilever {
  has Bool $.dev = False;
  has Str $.root = ".";
  has Str $.export-dir = "./export";
  has Int $.cache-life = 604800; # One week
  has Int $.port = 3000;
  has Str $.ip = "12.0.0.1";
  has Str $.content-dir = "content";
  has @.ignore = [];
  has @.ignore-cats = [];
  has @.custom-tags = [];
  has Str $.mimefile = "/etc/mime.types";

  has Web::App $!app;
  has HTTP::Easy::PSGI $!http;
  has Cantilever::Category $!pages = Cantilever::Category.new(
    path => $!content-dir.IO,
    root => $!root,
    custom-tags => @!custom-tags,
    ignore => [|@!ignore, |@!ignore-cats],
    dev => $!dev
  );

  has &.home is rw = -> %params { "<h1>Home</h1>"; }
  has &.archives is rw = -> %params { "<h1>Archives</h1>"; }
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
    if $path.is-file && $path ~~ none(|@!ignore) {
      $context.load-mime($!mimefile);
      $context.send-file($path.page-tree[*-1], content => $path.raw-file.IO.slurp(:bin));
    } elsif $path.is-home {
      $content = &!home({
        type => "home",
        content => $!pages,
        root => $!root
      });
      $context.set-status(200);
      $context.content-type('text/html');
      $context.send($content);
    } elsif $path.is-page && my $page = $!pages.get-page($path.page-tree) {
      $content = &!page({
        type => "page",
        content => $!pages,
        root => $!root,
        page => $page
      });
      $context.set-status(200);
      $context.content-type('text/html');
      $context.send($content);
    } elsif $path.is-category && my $category = $!pages.get-category($path.page-tree) {
      $content = &!category({
        type => "category",
        content => $!pages,
        root => $!root,
        category => $category
      });
      $context.set-status(200);
      $context.content-type('text/html');
      $context.send($content);
    } elsif $path.page-tree.elems == 1 && $path.page-tree[0] eq "archives" {
      $content = &!archives({
        type => "archives",
        content => $!pages,
        root => $!root
      });
      $context.set-status(200);
      $context.content-type('text/html');
      $context.send($content);
    } else {
      die Cantilever::Exception.new(
        code => 404,
        path => $path,
        message => "Couldn't find page {$context.path}"
      );
    }

    CATCH {
      default {
        my $err = $_;
        $context.set-status($err.?code || 500);
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

  method generate(Hash :$copy = Hash.new, Int :$regenerate-after = DateTime.now.posix) {
    $!pages.for-each(-> $p {
      mkpath($p.link($!export-dir));
      my $path = "{$p.link($!export-dir)}/index.html".IO;
      if $p ~~ Cantilever::Page {
        if $p.needs-rewrite($path, $regenerate-after) {
          say "Making {$p.link($!export-dir)}";
          spurt($path, &!page({
            type => "page",
            content => $!pages,
            root => $!root,
            page => $p
          }));
        } else {
          say "Using existing {$p.link($!export-dir)}";
        }
      } elsif $p ~~ Cantilever::Category {
        say "Making {$p.link($!export-dir)}";
        spurt($path, &!category({
          type => "category",
          content => $!pages,
          root => $!root,
          category => $p
        }));
      }
    });

    say "Making homepage";
    mkpath($!export-dir);
    my $home = "{$!export-dir}/index.html".IO;
    spurt($home, &!home({
      type => "home",
      content => $!pages,
      root => $!root
    }));

    say "Making archives";
    mkpath($!export-dir ~ "/archives");
    my $archives = "{$!export-dir}/archives/index.html".IO;
    spurt($archives, &!archives({
      type => "archives",
      content => $!pages,
      root => $!root
    }));

    say "Making 404 page";
    my $err404 = "{$!export-dir}/404.html".IO;
    spurt($err404, &!error({
      type => "error",
      content => $!pages,
      root => $!root,
      error => Cantilever::Exception.new(
        code => 404,
        message => "Sorry, we couldn't find the page you were looking for."
      )
    }));

    for $copy.kv -> $k, $v {
      say "Copying $k to {$!export-dir}/{$v}";
      cp($k, "{$!export-dir}/{$v}", :r);
    }
  }

  method run {
    $!http = HTTP::Easy::PSGI.new(ip => $.ip, port => $.port);
    $!app = Web::App.new($!http);
    $!app.run: &!handler;
  }

  method get($url) {
    my $context = Cantilever::Test::Context.new(path => $url);
    &!handler($context);
    return $context.to-hash;
  }
}
