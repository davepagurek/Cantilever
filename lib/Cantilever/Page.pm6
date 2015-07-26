use v6;

use Cantilever::Page::Actions;
use Cantilever::Page::Grammar;
use Cantilever;
use JSON::Tiny;

class Cantilever::Page {
  has Str $.content;
  has Hash $.meta;
  has Bool $.valid;
  has Cantilever $.app;

  submethod BUILD(:$content, :$app) {
    $!app = $app if $app;
    my $actions = Cantilever::Page::Actions.new;
    my $match = Cantilever::Page::Grammar.parse($content || "", actions => $actions);
    if $match {
      my $result = $match.made;
      $!valid = True;
      $!meta = from-json($result<meta>) if $result<meta>;
      $!content = $result<content> || "";
    } else {
      $!valid = False;
    }
  }

  method parse-results {
    {
      valid => $!valid,
      meta => $!meta,
      content => $!content
    }
  }
}
