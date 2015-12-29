use v6;
use JSON::Tiny;

use Cantilever::Page;
use Cantilever::Helpers;

class Cantilever::Category {
  has IO::Path $.path is required;
  has Hash %.pages = {};
  has Hash %.sub-cats = {};
  has Hash %.meta = {};

  has Str $!root;

  submethod BUILD(IO::Path :$path, Str :$root = ".") {
    $!path = $path;
    $!root = $root;

    if "$path/category.json".IO.e {
      %!meta = deep-map(
        from-json("$path/category.json".IO.slurp),
        -> $v { $v.subst(/'%root%'/, $!root); }
    }

    for $!path.dir -> $element {
      given $element {
        when :d {
          %!sub-cats{$element.basename} = Cantilever::Category.new(
            path => $element,
            root => $!root
          );
        }
        when all(:e, *.extension ~~ /^ 'htm' 'l'? $/) {
          %!pages{$element.basename.substr( 0 ..^ *-$element.extension.chars )} =
            Cantilever::Page.new(
              content => $element.slurp,
              root => $!root
            );
        }
      }
    }
  }
}
