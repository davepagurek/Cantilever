use Test;
plan *;

use lib "lib";
use Cantilever;
use Cantilever::Test::Helpers;

my $app = Cantilever.new(
  content-dir => "t/test-content"
);

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
}, "Gets the right status code";

done;
