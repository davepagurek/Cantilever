use v6;

grammar Cantilever::Path::Grammar {
  token TOP {
    ^^ [ '/' <name> ]*? '/'? $$
  }
  token name { <[ \w \- \. ]>+ }
}
