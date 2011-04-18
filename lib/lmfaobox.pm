package lmfaobox;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::FlashMessage;

our $VERSION = '1.0';

get '/' => sub {
    if ($ENV{REMOTE_USER}) {
        template 'admin';
    } else {
        template 'index';
    }
};

post '/add/address' => sub {
    database->quick_insert('members', { 
                                name => params->{'name'}, 
                                address => params->{'address'} 
                            }) 
        or flash(error => $DBI::errstr);

    flash(info => 'Added your address');
    redirect '/';
};

true;
