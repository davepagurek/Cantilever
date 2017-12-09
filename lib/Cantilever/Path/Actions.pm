use v6;

class Cantilever::Path::Actions {
  method name($/) {
    $/.make: ~$/;
  }
  method TOP($/) {
    $/.make: $<name> ?? $<name>.map(*.made) !! [];
  }
}
