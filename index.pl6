use v6;
use lib 'lib';
use Cantilever;

my $app = Cantilever.new(
  dev => True,
  port => 3000,
  root => "http://localhost:3000",
  cacheLife => 0
);

$app.run;
