use Cantilever::Path::Actions;
use Cantilever::Path::Grammar;

class Cantilever::Path {
  method parse($string) {
    my $actions = Cantilever::Path::Actions.new;
    my $match = Cantilever::Path::Grammar.parse($string, actions => $actions);
    return $match.made if $match;
    return {valid => False};
  }
}
