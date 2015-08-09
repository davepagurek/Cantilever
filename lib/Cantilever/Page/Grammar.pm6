grammar Cantilever::Page::Grammar {
  rule TOP {
    ^ <content>
  }

  rule content {
    <block>* $
  }

  proto rule block {*};
  rule block:sym<heading-tag> {
    '<' $<tag-type>=[ ['h'\d+] | 'p' | 'strong' | 'em' | 'u' | 'strike' ] '>' <text>* '</' $<tag-type> '>'
  }

  rule block:sym<code> {
    ['<' 'code' [ 'lang' '=' <quote> $<language>=[\w+] <quote> ]? '>' $<raw>=.*? '<' '/' 'code' '>']
    |
    ['```'[' '$<language>=[\w+]]? $<raw>=.*? '```']
  }

  rule block:sym<captioned-image> {
    {} '<img'
      'src' '=' <quote>$<src>=.*?<quote>
      'full' '=' <quote>$<full>=.*?<quote>
      'caption' '=' <quote>$<caption>=<text>*?<quote>
    '/'? '>'
  }

  rule block:sym<comment> {
    '<!--' .*? '-->'
  }

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
