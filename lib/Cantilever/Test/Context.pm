class Cantilever::Test::Context {
  has $.path;
  has $.status is rw;
  has $.type is rw;
  has $.response is rw;

  method set-status($status) {
    $.status = $status;
  }

  method content-type($type) {
    $.type = $type;
  }

  method send($response) {
    $.response = $response;
  }

  method to-hash {
    {
      status => $.status,
      type => $.type,
      response => $.response
    }
  }
}
