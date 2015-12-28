use v6;

use Cantilever::Path::Actions;
use Cantilever::Path::Grammar;

class Cantilever::Path {
  has Str $.content-dir = "";
  has Str $.path = "";

  has Bool $!valid = False;
  has @!page-tree = [];
  has $!home;
  has $!page;
  has $!category;

  submethod BUILD(:$path, :$content-dir) {
    $!content-dir = $content-dir if $content-dir;
    $!path = $path if $path;
    my $actions = Cantilever::Path::Actions.new;
    my $match = Cantilever::Path::Grammar.parse($path, actions => $actions);
    if $match {
      @!page-tree = $match.made;
    } else {
      $!valid = False;
    }
  }

  method parse-results {
    {
      valid => $!valid,
      page-tree => @!page-tree;
    }
  }

  method is-home {
    @!page-tree.elems == 0;
  }

  method is-page {
    !self.is-home && self.source-file.IO.e;
  }

  method is-category {
    !self.is-home && self.source-dir.IO.d;
  }

  method source-file {
    $!home ?? "$.content-dir/index.html" !! "$.content-dir/{@!page-tree.join('/')}.html";
  }

  method source-dir {
    "$.content-dir/{@!page-tree.join('/')}";
  }
}
