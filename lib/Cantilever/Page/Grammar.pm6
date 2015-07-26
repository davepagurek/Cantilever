use Grammar::Tracer;
grammar Cantilever::Page::Grammar {
  rule TOP {
    ^ <meta>?<content>
  }

  # Meta
  rule meta {
    '<!--' <object> '-->'
  }

  rule object     { '{' ~ '}' <pairlist>     }
  rule pairlist   { <pair> * % \,            }
  rule pair       { <string> ':' <value>     }
  rule array      { '[' ~ ']' <arraylist>    }
  rule arraylist  {  <value> * % [ \, ]      }

  proto token value {*};
  token value:sym<number> {
    '-'?
    [ 0 | <[1..9]> <[0..9]>* ]
    [ \. <[0..9]>+ ]?
    [ <[eE]> [\+|\-]? <[0..9]>+ ]?
  }
  token value:sym<true>    { <sym>    };
  token value:sym<false>   { <sym>    };
  token value:sym<null>    { <sym>    };
  token value:sym<object>  { <object> };
  token value:sym<array>   { <array>  };
  token value:sym<string>  { <string> }

  token string {
    \" ~ \" [ <str> | \\ <str=.str_escape> ]*
  }
  token str {
    <-["\\\t\n]>+
  }

  token str_escape {
    <["\\/bfnrt]> | 'u' <utf16_codepoint>+ % '\u'
  }
  token utf16_codepoint {
    <.xdigit>**4
  }


  #Content
  rule content {
    <block>* $
  }

  proto rule block {*};
  rule block:sym<heading-tag> {
    '<' $<tag-type>=[ ['h'\d+] | 'p' | 'strong' | 'em' | 'u' | 'strike' ] '>' <text> '</' $<tag-type> '>'
  }

  rule block:sym<code> {
    ['<' 'code' [ 'lang' '=' <quote> $<language>=[\w+] <quote> ]? '>' $<raw>=.*? '<' '/' 'code' '>']
    ||
    ['```'[' '$<language>=[\w+]]? $<raw>=.*? '```']
  }

  #rule item:<inline-code> {
    #'`'<raw>*'`'
    #||
    #'<span class="code">'<raw>*'</span>'
  #}

  #rule item:<captioned-image> {
    #'<img'
      #'src' '=' <quote>$<src>=<raw><quote>
      #'full' '=' <quote>$<full>=<raw><quote>
      #'caption' '=' <quote>$<caption>=<raw><quote>
    #'/'? '>'
  #}

  rule block:sym<line> {
     <:!r text>
  }

  proto regex text {*};
  regex text:sym<plaintext> {\N+}

  token quote {
    \" | \'
  }

 }
