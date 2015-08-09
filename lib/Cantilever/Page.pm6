use v6;

use Cantilever::Page::Actions;
use Cantilever::Page::Grammar;
use Cantilever;
use JSON::Tiny;

class Cantilever::Page {
  has Str $.source;
  has Str $.content;
  has Hash $.meta;
  has Bool $.only-meta;
  has Cantilever $.app;

  submethod BUILD(:$content is copy, :$source, :$app, :$only-meta = False) {
    $!app = $app if $app;
    $!only-meta = $only-meta;
    unless $content {
      die "No source provided" unless $source;
      $content = $source.IO.slurp;
    }
    $content.subst-mutate("%root%", $app.root) if $app;

    self!parse-meta($content);
    self!parse-content($content) unless $only-meta;
  }

  method !parse-meta($content is rw) {
    my $match = $content.subst-mutate(/ ^ '<!--' $<json>=[ .*? ] '-->' /, "");
    $!meta = from-json(~$match<json>.trim) if $match && ~$match<json>.trim.chars > 0;
  }

  method !parse-content($content is rw) {
    my $actions = Cantilever::Page::Actions.new;
    my $match = Cantilever::Page::Grammar.parse($content || "", actions => $actions);
    die "Couldn't parse source content" unless $match;
    $!content = $match.made || "";
  }
}
