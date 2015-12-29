use v6;

use HTML::Entity;
use Cantilever::Page::Actions;
use Cantilever::Page::Grammar;
use Cantilever::Page::Types;
use Cantilever::Helpers;
use Cantilever::Exception;

class Cantilever::Page {
  has %.meta;
  has Str $.slug = "UNTITLED";
  has @.category-tree;

  has Cantilever::Page::PageSource $!ast;
  has Str $!rendered;
  has Str $!root = ".";
  has @!custom-tags;

  submethod BUILD(:@category-tree = [], Str :$slug, Str :$content, Str :$root, :@custom-tags = []) {
    $!root = $root if $root;
    $!slug = $slug if $slug;
    @!custom-tags = @custom-tags;
    @!category-tree = [];

    my $actions = Cantilever::Page::Actions.new;
    my $match = Cantilever::Page::Grammar.parse($content || "", actions => $actions);
    unless $match {
      die Cantilever::Exception.new(
        code => 500,
        page => "{@!category-tree.join('/')}/$slug",
        message => "Couldn't parse source content"
      );
    }
    $!ast = $match.made;
    %!meta = deep-map($!ast.meta, -> $v { $v.subst(/'%root%'/, $!root); });
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

  method link returns Str {
    $!root ~ @.category-tree.join("/") ~ "/$.slug";
  }
}
