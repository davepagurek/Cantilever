use v6;

use HTML::Entity;
use Cantilever::Page::Actions;
use Cantilever::Page::Grammar;
use Cantilever::Page::Types;
use Cantilever;

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
    #$content.subst-mutate("%root%", $app.root) if $app;

    if $only-meta {
      self!parse-meta($content);
    } else {
      self!parse-content($content);
    }
  }

  method !parse-meta($content is rw) {
    my $match = $content.subst-mutate(/ ^ '<!--' $<json>=[ .*? ] '-->' /, "");
    $!meta = from-json(~$match<json>.trim) if $match && ~$match<json>.trim.chars > 0;
  }

  method !parse-content($content is rw) {
    my $actions = Cantilever::Page::Actions.new;
    my $match = Cantilever::Page::Grammar.parse($content || "", actions => $actions);
    die "Couldn't parse source content" unless $match;
    my $ast = $match.made;
    $!content = $ast.to-html({
      root => $.app.root,
      custom-tags => [
        Cantilever::Page::CustomTag.new(
          matches-fn => -> $t { $t.type eq "img" && $t.attributes<full> },
          render-fn => -> $t, %options {
            my $caption = "";
            if $t.attributes<caption> {
              $caption = "<p class='caption'>" ~
                $t.attributes<caption>.subst(
                  /'`'$<code>=(.+?)'`'/,
                  -> $/ {'<span class=\'code\'>' ~ $<code> ~ '</span>'}
                ) ~
                "</p>";
            }

            "<div class='img'>"
            ~ "<a href='{$t.attributes<full>}'>"
            ~ "<img src='{$t.attributes<src>}' />"
            ~ "</a>"
            ~ $caption
            ~ "</div>";
          },
          block => True
        ),
        Cantilever::Page::CustomTag.new(
          matches-fn => -> $t { $t.type eq "code" },
          render-fn => -> $t, %options {
            "<pre><code" ~
              ($t.attributes<lang> ??
                " class='{$t.attributes<lang>}'" !!
                "") ~
              ">" ~
              $t.children[0].to-html(%options) ~
              "</code></pre>";
          },
          block => True
        )
      ]
    });
    $!meta = deep-map($ast.meta, -> $v { $v.subst(/'%root%'/, $.root); });
  }
}
