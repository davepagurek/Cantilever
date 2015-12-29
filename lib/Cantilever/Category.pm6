use v6;
use JSON::Tiny;

use Cantilever::Page;
use Cantilever::Helpers;

class Cantilever::Category {
  has IO::Path $.path;
  has Cantilever::Page %.pages = {};
  has Cantilever::Category %.sub-cats = {};
  has %.meta = {};

  has Str $!root;

  submethod BUILD(IO::Path :$path, Str :$root = ".") {
    $!path = $path;
    $!root = $root;

    die "Path $path does not exist!" unless $path.e;

    if "$path/category.json".IO.e {
      %!meta = deep-map(
        from-json("$path/category.json".IO.slurp),
        -> $v { $v.subst(/'%root%'/, $!root); }
      );
    }

    for $!path.dir -> $element {
      if $element.d {
        %!sub-cats{$element.basename} = Cantilever::Category.new(
          path => $element,
          root => $!root
        );
      } elsif $element.e &&  $element.extension ~~ /^ 'htm' 'l'? $/ {
        %!pages{
          $element.basename.substr(0, *-$element.extension.chars-1)
        } = Cantilever::Page.new(
          content => $element.slurp,
          root => $!root
        );
      }
    }
  }

  method get-page(@page-tree) returns Cantilever::Page {
    if @page-tree.elems == 0 {
      die "Page is actually a category!";
    } elsif @page-tree.elems > 1 {
      %.sub-cats{@page-tree[0]}.?get-page(@page-tree[1 .. *-1]);
    } else {
      %.pages{@page-tree[0]};
    }
  }

  method get-category(@page-tree) returns Cantilever::Category {
    if @page-tree.elems == 0 {
      self;
    } else {
      %.sub-cats{@page-tree[0]}.?get-category(@page-tree[1 .. *-1]);
    }
  }

  method to-hash returns Hash {
    Hash.new(
      %!pages.kv.map(-> $k, $v { $k => True }),
      %!sub-cats.kv.map(-> $k, $v { $k => $v.to-hash })
    );
  }
}
