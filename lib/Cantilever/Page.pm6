use v6;

use Cantilever::Page::Actions;
use Cantilever::Page::Grammar;

class Cantilever::Page {
  has Str $.path = "";
  has Cantilever $.app;

  submethod BUILD(:$path, :$app) {
    $.path = $path;
    $.app = $app;
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
}
