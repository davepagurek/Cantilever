use v6;
use Test;
plan *;

use lib "lib";
use Cantilever;
use Cantilever::Test::Helpers;

my $app = Cantilever.new(
  content-dir => "t/test-content"
);

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

done-testing;
