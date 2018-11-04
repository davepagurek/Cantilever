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
  has Bool $.dev;

  has Cantilever::Page::PageSource $!ast;
  has Str $!rendered;
  has Str $!root = ".";
  has @!custom-tags;
  has Int $!source-modified-at;

  submethod BUILD(:@category-tree = [], Str :$slug, Str :$content, Str :$root, :@custom-tags = [], :@meta-maps = [], :$dev = False, Int :$source-modified-at = DateTime.now.posix) {
    $!root = $root if $root;
    $!slug = $slug if $slug;
    @!custom-tags = @custom-tags;
    @!category-tree = @category-tree;
    $!dev = $dev;
    $!source-modified-at = $source-modified-at;

    my $actions = Cantilever::Page::Actions.new;
    my $match = Cantilever::Page::Grammar.parse($content || "", actions => $actions);
    unless $match {
      if $!dev {
        my $attempt = Cantilever::Page::Grammar.subparse($content || "");
        die Cantilever::Exception.new(
          code => 500,
          page => "{@!category-tree.join('/')}/$slug",
          message => "Couldn't parse source content. Farthest parse:\n{$attempt.gist}\n\nOriginal:$content"
        );
      } else {
        die Cantilever::Exception.new(
          code => 500,
          page => "{@!category-tree.join('/')}/$slug",
          message => "Couldn't parse source content"
        );
      }
    }
    $!ast = $match.made;
    %!meta = Hash.new(
      deep-map($!ast.meta, -> $v { $v.subst(/'%root%'/, $!root) })
      .kv
      .map(-> $k, $v {
        given $k {
          when 'date' {
            $k => Date.new($v);
          }
          default {
            $k => $v;
          }
        }
      })
    );
  }

  method cat-slug returns Str {
    @!category-tree[*-1];
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

  method link(Str $root = $!root) returns Str {
    $root  ~ '/' ~ @.category-tree[1..*-1].join("/") ~ "/$.slug";
  }

  method date-tag returns Str {
    return "<!-- CANTILEVER-MODIFIED-AT {DateTime.now.posix.Str} -->";
  }

  method needs-rewrite(IO $file, Int $regenerate-after) returns Bool {
    if (!$file.e) {
      # File does not exist, we need to make it
      return True;
    }

    for $file.lines -> $line {
      if $line ~~ / '<!-- CANTILEVER-MODIFIED-AT ' $<timestamp>=[ \d+ ] ' -->' / {
        my $last-modified-at = $<timestamp>.Int;

        if $regenerate-after > 0 && $last-modified-at < $regenerate-after {
          return True;
        }

        # Return whether or not the source file has been updated since last time
        return $last-modified-at < $!source-modified-at;
      }
    }

    # Otherwise, assume it needs to be regenerated
    return True;
  }
}
