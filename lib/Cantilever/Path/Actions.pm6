class Cantilever::Path::Actions {
  method category($/) {
    $/.make(~$/);
  }
  method page($/) {
    $/.make(~$/);
  }
  method TOP($/) {
    $/.make: {
      home => (not $<category>) && (not $<page>),
      category => $<category> ?? $<category>.made !! False,
      page => $<page> ?? $<page>.made !! False
    };
  }
}
