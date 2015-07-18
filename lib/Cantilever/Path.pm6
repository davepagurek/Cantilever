use v6;

use Cantilever::Path::Actions;
use Cantilever::Path::Grammar;

class Cantilever::Path {
  has Str $.content-dir = "";

  has $!valid = False;
  has $!home;
  has $!page;
  has $!category;

  submethod BUILD(:$path) {
    my $actions = Cantilever::Path::Actions.new;
    my $match = Cantilever::Path::Grammar.parse($path, actions => $actions);
    if $match {
      my $result = $match.made;
      $!valid = True;
      $!home = $result<home>;
      $!page = $result<page>;
      $!category = $result<category>;
    } else {
      $!valid = False;
    }
  }

  method parse-results {
    {
      valid => $!valid,
      home => $!home,
      page => $!page,
      category => $!category
    }
  }

  method is-home {
    ? $!home;
  }

  method is-page {
    (? $!page) && ("$!category/$!page.html".IO ~~ :e);
  }

  method is-category {
    (? $!category) && ($!category.IO ~~ :d);
  }
}
