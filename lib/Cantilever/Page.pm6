use v6;

use HTML::Entity;
use Cantilever::Page::Actions;
use Cantilever::Page::Grammar;
use Cantilever::Page::Types;
use Cantilever;

class Cantilever::Page {
  has Hash $.meta;

  has Cantilever::Page::PageSource $!ast;
  has Str $!rendered;
  has @!custom-tags;
  has Str $!root;

  sub deep-map($var, &replacement) {
    if $var.isa(Str) {
      &replacement($var);
    } elsif $var.isa(Hash) {
      Hash.new($var.kv.map(-> $k, $v {
        $k => deep-map($v, &replacement);
      }));
    } elsif $var.isa(Array) {
      Array.new($var.list.map(-> $el {
        deep-map($el, &replacement);
      }));
    } else {
      $var;
    }
  }

  submethod BUILD(Str :$content, Str :$root = ".", :@custom-tags = []) {
    $!root = $root;
    @!custom-tags := @custom-tags;

    my $actions = Cantilever::Page::Actions.new;
    my $match = Cantilever::Page::Grammar.parse($content || "", actions => $actions);
    die "Couldn't parse source content!" unless $match;
    $!ast = $match.made;
    $!meta = deep-map($!ast.meta, -> $v { $v.subst(/'%root%'/, $!root); });
  }

  method rendered returns Str {
    unless $!rendered {
      $!rendered = $!ast.to-html({
        root => $!root,
        custom-tags => @!custom-tags
      });
    }

    $!rendered;
  }
}
