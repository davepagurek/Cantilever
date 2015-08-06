grammar Cantilever::Page::Grammar {
  rule TOP {
    ^ <meta>?<content>
  }

  rule meta {
    '<!--' $<json>=.+? '-->'
  }

  rule content {
    <block>* $
  }

  proto rule block {*};
  rule block:sym<heading-tag> {
    '<' $<tag-type>=[ ['h'\d+] | 'p' | 'strong' | 'em' | 'u' | 'strike' ] '>' <text> '</' $<tag-type> '>'
  }

  rule block:sym<code> {
    ['<' 'code' [ 'lang' '=' <quote> $<language>=[\w+] <quote> ]? '>' $<raw>=.*? '<' '/' 'code' '>']
    |
    ['```'[' '$<language>=[\w+]]? $<raw>=.*? '```']
  }

  

  #rule item:<captioned-image> {
    #'<img'
      #'src' '=' <quote>$<src>=<raw><quote>
      #'full' '=' <quote>$<full>=<raw><quote>
      #'caption' '=' <quote>$<caption>=<raw><quote>
    #'/'? '>'
  #}

  rule block:sym<line> {
    {} <text>+
  }

  proto regex text {*};
  regex text:sym<inline-code> {
    ['`'$<raw>=.*?'`']
    ||
    ['<span class="code">'$<raw>=.*?'</span>']
  }
  regex text:sym<plaintext> {{}\N+?}

  token quote {
    \" | \'
  }

 }
