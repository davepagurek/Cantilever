use v6;
use JSON::Tiny;

use Cantilever::Page;
use Cantilever::Helpers;
use Cantilever::Exception;

class Cantilever::Category {
  has IO::Path $.path;
  has Str $.slug;
  has Cantilever::Page %.pages = {};
  has Cantilever::Category %.sub-cats = {};
  has @.category-tree;
  has %.meta = {};
  has Bool $.dev;

  has @!custom-tags;
  has Str $!root;

  submethod BUILD(:@ignore = [], :@category-tree = [], IO::Path :$path, Str :$root = ".", :@custom-tags = [], Bool :$dev = False) {
    $!path = $path;
    $!slug = $!path.basename;
    $!root = $root;
    @!custom-tags = @custom-tags;
    @!category-tree = @category-tree;
    $!dev = $dev;

    unless $path.e {
      die Cantilever::Exception.new(
        message => "Couldn't parse category out of nonexistant path $path",
        code => 500
      );
    }

    if "$path/category.json".IO.e {
      %!meta = deep-map(
        from-json("$path/category.json".IO.slurp),
        -> $v { $v.subst(/'%root%'/, $!root); }
      );
    }

    for $!path.dir -> $element {
      next if ~$element ~~ any(|@ignore);
      if $element.d {
        %!sub-cats{$element.basename} = Cantilever::Category.new(
          path => $element,
          root => $!root,
          custom-tags => @!custom-tags,
          category-tree => [ |@!category-tree, $!slug ],
          dev => $!dev
        );
      } elsif $element.e &&  $element.extension ~~ /^ 'htm' 'l'? $/ {
        my $slug = $element.basename.substr(0, *-$element.extension.chars-1);
        %!pages{$slug} = Cantilever::Page.new(
          content => $element.slurp,
          root => $!root,
          slug => $slug,
          custom-tags => @!custom-tags,
          category-tree => [ |@!category-tree, $!slug ],
          dev => $!dev
        );
      }
    }
  }

  method link returns Str {
    $!root ~ @.category-tree.join("/") ~ "/$.slug";
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
