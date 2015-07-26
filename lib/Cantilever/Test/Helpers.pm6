module Cantilever::Test::Helpers {
  sub hash-compare($got, $expected) is export {
    for $expected.keys -> $key {
      unless $expected{$key} eqv $got{$key} {
        say "For key $key: Expected $expected{$key}.perl(), got $got{$key}.perl().";
        say "\t$got.perl()";
        return False;
      }
    }
    return True;
  }

  sub multiline-compare($got, $expected) is export {
    my $result = "$got ".subst(/\s+/, " ", :g) eqv "$expected ".subst(/\s+/, " ", :g);
    unless $result {
      say "Expected $expected.perl(), got $got.perl().";
    }
    $result;
  }
}
