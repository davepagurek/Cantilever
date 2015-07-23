#use Test;
#plan *;

use lib "lib";
#use Cantilever::Page;
use Cantilever::Test::Helpers;

use Cantilever::Page::Grammar;

my $test = Q{
  This is a test
};
my $match = Cantilever::Page::Grammar.parse($test);

#subtest {
  #my $page-tests = [
    ## path, expected fields, description
    #["/", {home => True, category => False}, "Parses root"],
    #["/blog", {home => False, category => "blog"}, "Parses categories"],
    #["/blog/", {home => False, category => "blog"}, "Parses categories with trailing slash"],
    #["/blog/post", {home => False, category => "blog", page => "post"}, "Parses pages"],
    #["/blog/post/", {home => False, category => "blog", page => "post"}, "Parses pages with trailing slash"],
    #["/blog/post/something", {valid => False}, "Only parses category/page paths"],
  #];

  #for $page-tests.list -> $row {
    #my ($path, $expected, $description) = $row.list;
    #my $parsed = Cantilever::Path.new(path => $path);
    #ok(hash-compare($parsed.parse-results, $expected), $description);
  #}
#}, "Can parse paths";

#done;
