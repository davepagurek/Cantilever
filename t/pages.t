use Test;
plan *;

use lib "lib";
use Cantilever::Page;
use Cantilever::Test::Helpers;

my $app = Cantilever.new(
  content-dir => "t/test-content",
  root => ".",
);

subtest {
  my $page-tests = [
    # path, expected fields, description
    [
      "<h1>This is a title</h1>",
      "<h1>This is a title</h1>",
      "Keeps heading tag"
    ],
    [
      "<p>This is a paragraph</p>",
      "<p>This is a paragraph</p>",
      "Keeps paragraph tag"
    ],
    [
      "<p>This is a paragraph `with inline code`</p>",
      "<p>This is a paragraph <span class='code'>with inline code</span></p>",
      "Paragraphs can have inline code"
    ],
    [
      "This is a paragraph",
      "<p>This is a paragraph</p>",
      "Adds paragraph tag to bare line"
    ],
    [
      "This is a paragraph\n",
      "<p>This is a paragraph</p>",
      "Adds paragraph tag to bare line with newline"
    ],
    [
      "This is a <em>formatted</em> line",
      "<p>This is a <em>formatted</em> line</p>",
      "Keeps formatting tags"
    ],
    [
      "<code>my \$lang = \"perl6\";</code>",
      "<pre><code> my \$lang = \"perl6\"; </code></pre>",
      "Wraps code tag in pre tag"
    ],
    [
      "```\nmy \$lang = \"perl6\";```",
      "<pre><code> my \$lang = \"perl6\"; </code></pre>",
      "Parses markdown style code"
    ],
    [
      "<code lang='perl6'>my \$lang = \"perl6\";</code>",
      "<pre><code class='perl6'> my \$lang = \"perl6\"; </code></pre>",
      "Parses code language"
    ],
    [
      "``` perl6\nmy \$lang = \"perl6\";```",
      "<pre><code class='perl6'> my \$lang = \"perl6\"; </code></pre>",
      "Parses markdown style code with language"
    ],
    [
      "This is `code` in a line",
      "<p>This is <span class='code'>code</span> in a line</p>",
      "Inline code"
    ],
    [
      "This is <span class='code'>code</span> in a line",
      "<p>This is <span class='code'>code</span> in a line</p>",
      "Inline code as span"
    ],
    [
      "<img src='test.jpg' full='full.jpg' caption='test caption'>",
      "<div class='img'><a href='full.jpg'><img src='test.jpg' /></a> <p class='caption'>test caption</p></div>",
      "Images with caption tags are replaced"
    ],
    [
      "<img src='test.jpg' full='full.jpg' caption='test `code in a` caption'>",
      "<div class='img'><a href='full.jpg'><img src='test.jpg' /></a> <p class='caption'>test <span class='code'>code in a</span> caption</p></div>",
      "Images with caption tags can have code"
    ],
    [
      "<p><a href='%root%/some/page'>Link</a></p>",
      "<p><a href='./some/page'>Link</a></p>",
      "Replaces %root% with app root"
    ],
    [
      "<!-- \{\} --> <h1>Test</h1>",
      "<h1>Test</h1>",
      "Meta is removed from content"
    ],
    [
      "<!-- \{\} --> <!-- comment --> <h1>Test</h1>",
      "<!-- comment --> <h1>Test</h1>",
      "Non-meta comments are left in"
    ],
  ];

  for $page-tests.list -> $row {
    my ($content, $expected, $description) = $row.list;
    my $parsed = Cantilever::Page.new(content => $content, app => $app);
    ok(multiline-compare($parsed.content, $expected), $description);
  }

  done-testing;
}, "Can parse basic pages";

subtest {
  my $meta-tests = [
    [
      '<!-- { "title": "Test Page" } --> Test',
      { title => "Test Page" },
      "Parses meta as JSON"
    ],
  ];

  for $meta-tests.list -> $row {
    my $content = $row.list[0];
    my $expected = $row.list[1];
    my $description = $row.list[2];
    say "Row:";
    my $parsed = Cantilever::Page.new(content => $content, app => $app);
    ok(hash-compare($parsed.meta, $expected), $description);
  }

  done-testing;
}, "Can parse meta";

done-testing;
