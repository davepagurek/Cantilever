use v6;
use Cantilever::Path;

class Cantilever::Exception is Exception {
  has Int $.code is required;
  has Str $.message = "";
  has Cantilever::Path $.path;
  has $.page;
  has $.category;
}
