use Cantilever::Page::Types;
use HTML::Entity;

class Cantilever::Page::Actions {
  method TOP($/) {
    $/.make: Cantilever::Page::PageSource.new(
      content => $<content>.made,
      meta => $<meta> ?? $<meta>.made !! {}
    );
  }
  method content($/) {
    $/.make: $<line> ?? $<line>.map(*.made) !! [];
  } 
  method meta($/) {
    $/.make: $<object>.made;
  }

  # line
  method line:sym<heading>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "h{~$<level>.chars}",
      children => $<text>.map(*.made)
    );
  }
  method line:sym<ul>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "ul",
      children => $<li>.map(*.made)
    );
  }
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

  method li($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "li",
      children => $<text>.map(*.made)
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
      attributes => { class => "code" },
      children => [ Cantilever::Page::SourceCode.new(src => ~$<text>) ]
    );
  }
  method node:sym<bold>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "strong",
      children => [ Cantilever::Page::Text.new(txt => ~$<text>) ]
    );
  }
  method node:sym<italic>($/) {
    $/.make: Cantilever::Page::Tag.new(
      type => "em",
      children => [ Cantilever::Page::Text.new(txt => ~$<text>) ]
    );
  }
  method node:sym<text-node>($/) {
    $/.make: Cantilever::Page::Text.new(txt => ~$/.subst(
      /\\<[ \n \` \\ \< \> \* ]>/,
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
      children => $<node> ?? $<node>.map(*.made) !! []
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
  method attribute:sym<flag-attribute>($/) {
    $/.make: (~$<attr> => "true");
  }
  method attr-name($/) {
    $/.make: (~$/);
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
