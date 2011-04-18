package lmfaobox;
use Dancer ':syntax';

our $VERSION = '1.0';

get '/' => sub {
    if ($ENV{REMOTE_USER}) {
        template 'admin';
    } else {
        template 'index';
    }
};

true;
