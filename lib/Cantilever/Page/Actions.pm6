class Cantilever::Page::Actions {
  method text:sym<plaintext>($/) {
    $/.make: ~$/;
  }
  method text:sym<inline-code>($/) {
    $/.make: "<span class='code'>{$<raw>}</span>";
  }
  method block:sym<line>($/) {
    my $content = "";
    for $<text>.list -> $text {
      $content ~= $text.made;
    }
    $/.make: "<p>{$content}</p>\n";
  }
  method block:sym<heading-tag>($/) {
    $/.make: "<{$<tag-type>}>{$<text>.made}</{$<tag-type>}>\n";
  }
  method block:sym<code>($/) {
    $/.make: "<pre><code{" class='"~$<language>~"'" if $<language>}>\n{$<raw>}\n</code></pre>";
  }
  method content($/) {
    my $content = "";
    for $<block>.list -> $block {
      $content ~= $block.made;
    }
    $/.make: $content;
  }
  method TOP($/) {
    $/.make: {
      meta => $<meta> ?? $<meta>.made !! {},
      content => $<content>.made
    };
  }
}
