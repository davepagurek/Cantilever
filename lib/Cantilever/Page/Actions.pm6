use HTML::Entity;

role Cantilever::Page::SourceNode {
  method to-html() { ... }
}

class Cantilever::Page::PageSource does Cantilever::Page::SourceNode {
  has @.content = [];
  has %.meta = {};
  method to-html() {
    @.content.map(*.to-html).join("\n");
  }
}

class Cantilever::Page::Text does Cantilever::Page::SourceNode {
  has Str $.txt is required;
  method to-html() { $.txt }
}

class Cantilever::Page::SourceCode does Cantilever::Page::SourceNode {
  has Str $.src = "";
  method to-html() {
    encode-entities($.src);
  }
}

class Cantilever::Page::Comment does Cantilever::Page::SourceNode {
  has Str $.content = "";
  method to-html() {
    $.content;
  }
}

class Cantilever::Page::Tag does Cantilever::Page::SourceNode {
  has Str $.type is required;
  has %.attributes = {};
  has @.children = [];
  has @!renderers = [
    {
      matches => -> $t { $t.type eq "img" && $t.attributes<full> },
      render => -> $t {
        "<div class='image'>"
        ~ "<a href='{$t.attributes<full>}'>"
        ~ "<img src='{$t.attributes<src>}'/></a>"
        ~ "</a>"
        ~ ($t.attributes<caption> ?? "<p>{$t.attributes<caption>}</p>" !! "")
        ~ "</div>";
      }
    },
    {
      matches => -> $t { $t.type eq "code" },
      render => -> $t {
        "<pre><code" ~
          ($t.attributes<lang> ??
            " class='{$t.attributes<lang>}'" !!
            "") ~
          ">" ~
          $t.children[0].to-html ~
          "</code></pre>";
      }
    },
  ];
  method !attributesToHTML() {
    %.attributes.kv.map(-> $k, $v { "$k='$v'" }).join(" ");
  }
  method to-html() {
    my $customTag = @!renderers.first(-> $x {$x<matches>(self)});
    if $customTag {
      $customTag<render>(self);
    } elsif @.children.elems == 0 {
      "<$.type {self!attributesToHTML()} />";
    } else {
      "<$.type {self!attributesToHTML()}>" ~
      @.children.map(*.to-html) ~
      "</$.type>";
    }
  }
}

class Cantilever::Page::Line does Cantilever::Page::SourceNode {
  has @.children is required;
  method to-html() {
    if @.children.elems == 1 && @.children[0].isa(Cantilever::Page::Tag) {
      @.children[0].to-html;
    } else {
      "<p>" ~ @.children.map(*.to-html).join("") ~ "</p>";
    }
  }
}

class Cantilever::Page::Actions {
  method TOP($/) {
    $/.make: Cantilever::Page::PageSource.new(
      content => $<content>.made,
      meta => {}
      #meta => $meta.made
    );
  }
  method content($/) {
    $/.make: $<line> ?? $<line>.map(*.made) !! [];
  } 
  method meta($/) {
    $/.make: $<object>.made;
  }

  # line
  method line:sym<nodes>($/) {
    $/.make: Cantilever::Page::Line.new(children => $<node>.map(*.made));
  }
  method line:sym<code>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "code",
      attributes => $<str> ?? {lang => ~$<str>} !! {},
      children => [ Cantilever::Page::SourceCode.new(src => ~$<src>.subst("\\\`", "`", :g)) ]
    );
  }  

  # node
  method node:sym<xml>($/) {
    $/.make: $<tag>.made;
  }
  method node:sym<comment>($/) {
    $/.make: Cantilever::Page::Comment.new(content => ~$/);
  }
  method node:sym<inline-code>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "span",
      attributes => Hash.new(class => "code"),
      children => [ Cantilever::Page::SourceCode.new(src => ~$<text>) ]
    );
  }
  method node:sym<text-node>($/) {
    $/.make: Cantilever::Page::Text.new(txt => ~$/.subst(
      /<[ \n \` \\ \< \> ]>/,
      -> $escaped { encode-entities($escaped.substr(1)) },
      :g
    ));
  }
  method tag:sym<self-closing-tag>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => ~$<attr-name>,
      attributes => $<attributes>.made
    );
  }
  method tag:sym<wrapping-tag>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => ~$<tag-name>,
      attributes => $<attributes>.made,
      children => $<content>.made
      #children => []
      #children => gather for $<nodes>.?map(*.made).list { take $_ }
    )
  }
  method tag:sym<code-tag>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "code",
      attributes => $<attributes>.made,
      children => [ Cantilever::Page::SourceCode.new(src => ~$<src>.subst("\\\`", "`", :g)) ]
    );
  }
  method attributes($/) {
    $/.make: $<attribute> ?? 
      Hash.new($<attribute>.list.map(*.made)) !!
      {};
  }
  method attribute:sym<quoted-attribute>($/) {
    $/.make: (~$<attr-name> => $<string>.made);
  }
  method attribute:sym<unquoted-attribute>($/) {
    $/.make: (~$<attr> => ~$<val>);
  }
  method attr-name($/) {
    $/.make: (~$/).substr(1, *-1);
  }

  
  # Meta
  method object($/) {
    make $<pairlist>.made.hash.item;
  }

  method pairlist($/) {
    make $<pair>>>.made.flat;
  }

  method pair($/) {
    make $<string>.made => $<value>.made;
  }

  method array($/) {
    make $<arraylist>.made.item;
  }

  method arraylist($/) {
    make [$<value>.map(*.made)];
  }

  method string:sym<single>($/) {
    make +@$<str-single> == 1
    ?? $<str-single>[0].made
    !! $<str-single>>>.made.join;
  }
  method string:sym<double>($/) {
    make +@$<str-double> == 1
    ?? $<str-double>[0].made
    !! $<str-double>>>.made.join;
  }
  method value:sym<number>($/) { make +$/.Str }
  method value:sym<string>($/) { make $<string>.made }
  method value:sym<true>($/) { make Bool::True  }
  method value:sym<false>($/) { make Bool::False }
  method value:sym<null>($/) { make Any }
  method value:sym<object>($/) { make $<object>.made }
  method value:sym<array>($/) { make $<array>.made }

  method str-single($/) { make ~$/ }
  method str-double($/) { make ~$/ }

  my %h = '\\' => "\\",
    '/'  => "/",
    'b'  => "\b",
    'n'  => "\n",
    't'  => "\t",
    'f'  => "\f",
    'r'  => "\r",
    '"'  => "\"",
    "'"  => "\'";
  method str_escape($/) {
    if $<utf16_codepoint> {
      make utf16.new( $<utf16_codepoint>.map({:16(~$_)}) ).decode();
    } else {
      make %h{~$/};
    }
  }
}
