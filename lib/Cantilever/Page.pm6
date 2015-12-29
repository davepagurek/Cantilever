use v6;

use HTML::Entity;
use Cantilever::Page::Actions;
use Cantilever::Page::Grammar;
use Cantilever::Page::Types;
use Cantilever::Helpers;

class Cantilever::Page {
  has %.meta;

  has Cantilever::Page::PageSource $!ast;
  has Str $!rendered;
  has Str $!root;

  submethod BUILD(Str :$content, Str :$root = ".") {
    $!root = $root;

    my $actions = Cantilever::Page::Actions.new;
    my $match = Cantilever::Page::Grammar.parse($content || "", actions => $actions);
    die "Couldn't parse source content!" unless $match;
    $!ast = $match.made;
    %!meta = deep-map($!ast.meta, -> $v { $v.subst(/'%root%'/, $!root); });
  }

  method rendered(:@custom-tags) returns Str {
    unless $!rendered {
      $!rendered = $!ast.to-html({
        root => $!root,
        custom-tags => @custom-tags
      });
    }

    $!rendered;
  }
}
