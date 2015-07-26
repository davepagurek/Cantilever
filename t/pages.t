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
    ["This is a paragraph", "<p>This is a paragraph</p>", "Adds paragraph tag to bare line"],
    ["This is a paragraph\n", "<p>This is a paragraph</p>", "Adds paragraph tag to bare line with newline"],
    ["This is a <em>formatted</em> line", "<p>This is a <em>formatted</em> line</p>", "Keeps formatting tags"],
    ["<code>my \$lang = \"perl6\";</code>", "<pre><code> my \$lang = \"perl6\"; </code></pre>", "Wraps code tag in pre tag"],
    ["```\nmy \$lang = \"perl6\";```", "<pre><code> my \$lang = \"perl6\"; </code></pre>", "Parses markdown style code"],
    ["<code lang='perl6'>my \$lang = \"perl6\";</code>", "<pre><code class='perl6'> my \$lang = \"perl6\"; </code></pre>", "Parses code language"],
    ["``` perl6\nmy \$lang = \"perl6\";```", "<pre><code class='perl6'> my \$lang = \"perl6\"; </code></pre>", "Parses markdown style code with language"],
  ];

  for $page-tests.list -> $row {
    my ($content, $expected, $description) = $row.list;
    my $parsed = Cantilever::Page.new(content => $content);
    ok(multiline-compare($parsed.parse-results<content>, $expected), $description);
  }
}, "Can parse basic pages";

done;
