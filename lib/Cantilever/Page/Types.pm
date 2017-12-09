use v6;
use HTML::Entity;

module Cantilever::Page::Types {
  class Cantilever::Page::CustomTag is export {
    has &.matches-fn is required;
    has &.render-fn is required;
    has Bool $.block = False;
    method matches($x) { &!matches-fn($x); }
    method render($x, %options) { &!render-fn($x, %options); }
  }

  role Cantilever::Page::SourceNode is export {
    method to-html(%options) { ... }
  }

  class Cantilever::Page::PageSource does Cantilever::Page::SourceNode is export {
    has @.content = [];
    has %.meta = {}; 
    method to-html(%options) {
      @.content.map(*.to-html(%options)).join("");
    }
  }

  class Cantilever::Page::Text does Cantilever::Page::SourceNode is export {
    has Str $.txt is required;
    method to-html(%options) {
      my $replaced = $.txt.subst(/'%root%'/, %options<root>);
      $replaced ~~ s/[['http' 's'? '://']? 'www.']? 'youtube.com/watch?v=' (<[\w\-]>+) '/'?/<iframe class="youtube embed" width="560" height="315" src="http:\/\/www.youtube.com\/embed\/$0?rel=0" frameborder="0" allowfullscreen><\/iframe>/;
      return $replaced;
    }
  }

  class Cantilever::Page::SourceCode does Cantilever::Page::SourceNode is export {
    has Str $.src = "";
    method to-html(%options) {
      encode-entities($.src);
    }
  }

  class Cantilever::Page::Comment does Cantilever::Page::SourceNode is export {
    has Str $.content = "";
    method to-html(%options) {
      $.content;
    }
  }

  class Cantilever::Page::Tag does Cantilever::Page::SourceNode is export {
    has Str $.type is required;
    has %.attributes = {};
    has %.formatted-attributes = {};
    has @.children = [];
    method !attributes-to-html(%options) {
      if %.attributes.elems > 0 { 
        " " ~ %.attributes.kv.map(-> $k, $v {
          "$k='{$v.subst(/'%root%'/, %options<root>)}'"
        }).join("");
      } else {
        ""
      }
    }
    method to-html(%options) {
      %.formatted-attributes = Hash.new(%.attributes.kv.map(-> $k, $v {
        $k => $v.subst(/'%root%'/, %options<root>);
      }));
      my $customTag = %options<custom-tags>.first(-> $x {$x.matches(self)});
      if $customTag {
        $customTag.render(self, %options);
      } elsif @.children.elems == 0 && $.type ne any("script", "iframe") {
        "<{$.type}{self!attributes-to-html(%options)} />";
      } else {
        "<{$.type}{self!attributes-to-html(%options)}>" ~
        @.children.map(*.to-html(%options)).join("") ~
        "</$.type>";
      }
    }
  }

  class Cantilever::Page::Line does Cantilever::Page::SourceNode is export {
    has @.children is required;
    method to-html(%options) {
      my $tag = @.children.first(-> $el {
        $el.isa(Cantilever::Page::Tag) &&
        (
          $el.type.lc ~~ any(/^^h\d+$$/, "p", "ul", "ol", "li", "div", "pre", "script", "hr")
          ||
          %options<custom-tags>.first(*.matches($el)).?block
        )
      });
      if $tag {
        @.children.map(*.to-html(%options)).join("");
      } else {
        "<p>" ~ @.children.map(*.to-html(%options)).join("") ~ "</p>";
      }
    }
  }
}
