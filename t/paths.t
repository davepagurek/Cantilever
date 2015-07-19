use v6;
use Test;
plan *;

use lib "lib";
use Cantilever::Path;
use Cantilever::Test::Helpers;

subtest {
  my $parse-tests = [
    # path, expected fields, description
    ["/", {home => True, category => False}, "Parses root"],
    ["/blog", {home => False, category => "blog"}, "Parses categories"],
    ["/blog/", {home => False, category => "blog"}, "Parses categories with trailing slash"],
    ["/blog/post", {home => False, category => "blog", page => "post"}, "Parses pages"],
    ["/blog/post/", {home => False, category => "blog", page => "post"}, "Parses pages with trailing slash"],
    ["/blog/post/something", {valid => False}, "Only parses category/page paths"],
  ];

  for $parse-tests.list -> $row {
    my ($path, $expected, $description) = $row.list;
    my $parsed = Cantilever::Path.new(path => $path);
    ok(hash-compare($parsed.parse-results, $expected), $description);
  }
}, "Can parse paths";

done;
