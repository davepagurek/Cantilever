use Test;
plan *;

use lib "lib";
use Cantilever::Page;
use Cantilever::Test::Helpers;

subtest {
  my $page-tests = [
    # path, expected fields, description
    ["<h1>This is a title</h1>", "<h1>This is a title</h1>", "Keeps heading tag"],
    ["<p>This is a paragraph</p>", "<p>This is a paragraph</p>", "Keeps paragraph tag"],
    ["<p>This is a paragraph `with inline code`</p>", "<p>This is a paragraph <span class='code'>with inline code</span></p>", "Paragraphs can have inline code"],
    ["This is a paragraph", "<p>This is a paragraph</p>", "Adds paragraph tag to bare line"],
    ["This is a paragraph\n", "<p>This is a paragraph</p>", "Adds paragraph tag to bare line with newline"],
    ["This is a <em>formatted</em> line", "<p>This is a <em>formatted</em> line</p>", "Keeps formatting tags"],
    ["<code>my \$lang = \"perl6\";</code>", "<pre><code> my \$lang = \"perl6\"; </code></pre>", "Wraps code tag in pre tag"],
    ["```\nmy \$lang = \"perl6\";```", "<pre><code> my \$lang = \"perl6\"; </code></pre>", "Parses markdown style code"],
    ["<code lang='perl6'>my \$lang = \"perl6\";</code>", "<pre><code class='perl6'> my \$lang = \"perl6\"; </code></pre>", "Parses code language"],
    ["``` perl6\nmy \$lang = \"perl6\";```", "<pre><code class='perl6'> my \$lang = \"perl6\"; </code></pre>", "Parses markdown style code with language"],
    ["This is `code` in a line", "<p>This is <span class='code'>code</span> in a line</p>", "Inline code"],
    ["This is <span class='code'>code</span> in a line", "<p>This is <span class='code'>code</span> in a line</p>", "Inline code as span"],
    ["<img src='test.jpg' full='full.jpg' caption='test caption'>", "<div class='img'><a href='full.jpg'><img src='test.jpg' /></a> <p class='caption'>test caption</p></div>", "Images with caption tags are replaced"],
    ["<img src='test.jpg' full='full.jpg' caption='test `code in a` caption'>", "<div class='img'><a href='full.jpg'><img src='test.jpg' /></a> <p class='caption'>test <span class='code'>code in a</span> caption</p></div>", "Images with caption tags can have code"],
  ];

  for $page-tests.list -> $row {
    my ($content, $expected, $description) = $row.list;
    my $parsed = Cantilever::Page.new(content => $content);
    ok(multiline-compare($parsed.parse-results<content>, $expected), $description);
  }
}, "Can parse basic pages";

done;
