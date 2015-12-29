use v6;
use Test;
plan *;

use lib "lib";
use Cantilever;
use Cantilever::Test::Helpers;

subtest {
  my $parse-tests = [
    # path, expected fields, description
    ["/", {page-tree => []}, "Parses root"],
    ["/blog", {page-tree => ["blog"]}, "Parses categories"],
    ["/blog/", {page-tree => ["blog"]}, "Parses categories with trailing slash"],
    ["/blog/post", {page-tree => ["blog", "post"]}, "Parses pages"],
    ["/blog/post/", {page-tree => ["blog", "post"]}, "Parses pages with trailing slash"],
    ["/blog/post/something", {page-tree => ["blog", "post", "something"]}, "Parses nested directory paths"],
    ["/blog/post//something", {valid => False}, "Doesn't parse invalid paths"],
  ];

  for $parse-tests.list -> $row {
    my ($path, $expected, $description) = $row.list;
    my $parsed = Cantilever::Path.new(path => $path);
    ok(hash-compare($parsed.parse-results, $expected), $description);
  }

  done-testing;
}, "Can parse paths";

subtest {
  my $app = Cantilever.new(
    content-dir => "t/test-content"
  );

  my $status-tests = [
    # path, expected fields, description
    ["/", {status => 200}, "Identifies root"],
    ["/blog", {status => 200}, "Real category"],
    ["/not_a_real_category", {status => 404}, "Not a real category"],
    ["/blog/hello_world", {status => 200}, "Real page"],
    ["/blog/not_a_real_page", {status => 404}, "Not a real page"],
  ];

  for $status-tests.list -> $row {
    my ($path, $expected, $description) = $row.list;
    my $response = $app.get($path);
    ok(hash-compare($response, $expected), $description);
  } 

  done-testing;
}, "Gets the right status code";

subtest {
  my $content = Cantilever::Category.new(path => "t/test-content".IO);
  is-deeply(
    $content.to-hash,
    {
      blog => { hello_world => True },
      portfolio => {
        test_art => True,
        programming => { test_programming => True }
      }
    },
    "Category parses all valid subpages and none extra"
  );
  is-deeply(
    $content.get-category(["blog"]).?meta,
    { name => "Blog", order => 4 },
    "Parses category json files"
  ); 

  done-testing;
}, "Can parse source content";

subtest {
  my $app = Cantilever.new(
    content-dir => "t/test-content",
    home => -> $c {
      "Home: {$c.sub-cats.elems} subcats, {$c.pages.elems} pages";
    },
    category => -> $c {
      "{$c.meta<name> || $c.slug}: " ~
      "{$c.sub-cats.elems} subcats, {$c.pages.elems} pages";
    },
    page => -> $p {
      "<h1>{$p.meta<title> || 'Untitled'}</h1> " ~
      $p.rendered;
    },
    error => -> $e {
      "<h1>{$e.?code || 500}</h1>";
    }
  );
  my @render-tests = [
    ["/", "Home: 2 subcats, 0 pages", "Renders home"],
    ["/blog", "Blog: 0 subcats, 1 pages", "Renders category"],
    ["/portfolio", "portfolio: 1 subcats, 1 pages", "Renders category with sub categories"],
    ["/blog/hello_world", "<h1>Hello, World</h1> <p>This is test content!</p> ", "Renders page"],
    ["/not_a_real_category", "<h1>404</h1>", "Renders error"]
  ];

  for @render-tests -> $row {
    my ($path, $expected, $description) = $row.list;
    my $response = $app.get($path)<response>;
    ok(multiline-compare($response, $expected), $description);
  }
}

done-testing;
