# Cantilever [![Build Status](https://travis-ci.org/davepagurek/Cantilever.svg?branch=master)](https://travis-ci.org/pahgawk/Cantilever)
A flat file CMS for Perl 6

## Usage
``` perl6
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
```

## Local development
Run tests:
```
PERL6LIB=lib prove -v -r --exec=perl6 t/
```
