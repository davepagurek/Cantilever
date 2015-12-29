use v6;

module Cantilever::Helpers {
  sub deep-map($var, &replacement) is export {
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
}
