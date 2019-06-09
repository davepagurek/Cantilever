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
  has %.meta;
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
    } else {
      %!meta = name => $!slug;
    }

    my $cat-lock = Lock.new;
    my $page-lock = Lock.new;
    await Promise.allof($!path.dir.map(-> $element {
      Promise.start({
        if ~$element ~~ any(|@ignore) {
          # Nothing
        } elsif $element.d {
          my $cat = Cantilever::Category.new(
            path => $element,
            root => $!root,
            custom-tags => @!custom-tags,
            category-tree => [ |@!category-tree, $!slug ],
            dev => $!dev
          );
          $cat-lock.protect({ %!sub-cats{$element.basename} = $cat; });
        } elsif $element.e &&  $element.extension ~~ /^ 'htm' 'l'? $/ {
          my $slug = $element.basename.substr(0, *-$element.extension.chars-1);
          my $page = Cantilever::Page.new(
            content => $element.slurp,
            root => $!root,
            slug => $slug,
            custom-tags => @!custom-tags,
            category-tree => [ |@!category-tree, $!slug ],
            dev => $!dev,
            source-modified-at => $element.modified.DateTime.posix
          );
          $page-lock.protect({ %!pages{$slug} = $page; });
        }
      });
    }));
  }

  method for-each(&callback) {
    await Promise.allof(
      self.all-pages.map(-> $page { Promise.start({ &callback($page); }) }),
      self.all-cats.map(-> $cat {
        Promise.start({
          &callback($cat);
          $cat.for-each(&callback);
        });
      })
    );
  }

  method link($root = $!root) returns Str {
    $root ~ @.category-tree[1..*-1].join("/") ~ "/$.slug";
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

  method all-pages returns Array {
    Array.new: %.pages.kv.map(-> $k, $v { $v }).sort(-> $v { $v.meta<date> }).reverse;
  }

  method pages-by-date returns Array {
    Array.new: self.all-pages.classify(-> $p { $p.meta<date>.year }).pairs.sort(*.key).reverse;
  }

  method all-cats returns Array {
    Array.new: %.sub-cats.kv.map(-> $k, $v { $v });
  }

  method to-hash returns Hash {
    Hash.new(
      %!pages.kv.map(-> $k, $v { $k => True }),
      %!sub-cats.kv.map(-> $k, $v { $k => $v.to-hash })
    );
  }
}
