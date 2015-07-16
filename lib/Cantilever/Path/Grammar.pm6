grammar Cantilever::Path::Grammar {
  token TOP {
    ^^ '/' [ <category> [ '/' <page> ]? '/'? ]? $$
  }
  token category { <name> }
  token page { <name> }
  token name { <[ \w \- ]>+ }
}
