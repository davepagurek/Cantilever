module Cantilever::Test::Helpers {
  sub hash-compare($got, $expected) is export {
    for $expected.keys -> $key {
      unless $expected{$key} eqv $got{$key} {
        say "For key $key: Expected $expected{$key}, got $got{$key}.";
        say "\t$got.perl()";
        return False;
      }
    }
    return True;
  }
}
