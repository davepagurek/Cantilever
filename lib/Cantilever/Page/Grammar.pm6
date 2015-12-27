#use Grammar::Tracer;
grammar Cantilever::Page::Grammar {
  # Page rules
  token TOP {
    ^
    <meta>? \n*
    <content> \n*
    $
  }
  token meta { '<!--' ~ '-->' [ \s* <object> \s* ] }
  token content { <line>* % \n+ }

  proto token line {*}
  token line:sym<nodes> { <node>+ }
  token line:sym<code> {
    ['```'[' '*$<str>=\w+]?\n] ~ ['```']
    $<src>=[<-[\`]> | "\\\`"]*
  }

  proto token node {*}
  token node:sym<xml> { <tag> }
  token node:sym<inline-code> {'`'~'`'[$<text>=[<-[\n \`]> | "\\'"]+]}
  token node:sym<text-node> {
    [
      <-[ \n \` \\ \< \>]> # All characters that aren't newlines or specials
      | [ \\ <[ \` \\ \< \> ]> ] # Escaped specials
    ]+
  }
  token node:sym<comment> { '<!--' .*? '-->' }

  proto token tag {*}
  token tag:sym<self-closing-tag> { '<' <attr-name> <attributes> \s* '/' '>' }
  token tag:sym<wrapping-tag> {
    [ '<' $<tag-name>=(<attr-name>) <?{~$<tag-name>.lc ne "code"}> <attributes> '>' ] ~ [ '<' '/' $<tag-name> '>' ]
    <node>*
  }
  token tag:sym<code-tag> {
    [ '<' 'code' <attributes> '>' ]
    [$<src>=[<-[<]> | '<' <!before '/' 'code' '>'>]*]
    [ '<' '/' 'code' '>' ]
  }
  rule attributes { \s* [<attribute>* % \s+] \s* }
  proto token attribute {*}
  token attribute:sym<quoted-attribute> { <attr-name> '=' <string> }
  token attribute:sym<unquoted-attribute> { $<attr>=<attr-name> '=' $<val>=<attr-name> }
  token attr-name { \w+ }


  # JSON rules
  rule object     { '{' ~ '}' <pairlist>     }
  rule pairlist   { <pair> * % \,            }
  rule pair       { <string> ':' <value>     }
  rule array      { '[' ~ ']' <arraylist>    }
  rule arraylist  {  <value> * % [ \, ]      }

  proto token value {*}
  token value:sym<number> {
    '-'?
    [ 0 | <[1..9]> <[0..9]>* ]
    [ \. <[0..9]>+ ]?
    [ <[eE]> [\+|\-]? <[0..9]>+ ]?
  }
  token value:sym<true>    { <sym>    }
  token value:sym<false>   { <sym>    }
  token value:sym<null>    { <sym>    }
  token value:sym<object>  { <object> }
  token value:sym<array>   { <array>  }
  token value:sym<string>  { <string> }

  proto token string {*}
  token string:sym<single> {
    \' [ <str-single> | \\ <str-single=.str_escape> ]* \'
  }
  token string:sym<double> {
    \" [ <str-double> | \\ <str-double=.str_escape> ]* \"
  }
  token str-single {
    <-['\\\t\n]>+
  }
  token str-double {
    <-["\\\t\n]>+
  }

  token str_escape {
    <['"\\/bfnrt]> | 'u' <utf16_codepoint>+ % '\u'
  }
  token utf16_codepoint {
    <.xdigit>**4
  }

 }
