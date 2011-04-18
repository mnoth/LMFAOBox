package lmfaobox;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::Email;
use Dancer::Plugin::FlashMessage;

use Data::Dumper;

use 5.012;

our $VERSION = '1.0';

get '/' => sub {
    if ($ENV{REMOTE_USER}) {
        template 'index';
    } else {
        template 'admin';
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

post '/message' => sub {
    foreach my $member (database->quick_select('members', { 1 => 1 } )) {
        email {
            to => $member->{address},
            from => 'ay1244@gmail.com',
            message => params->{'message'},
        };
    }

    flash(info => 'Message sent');
    redirect '/';
};

true;
