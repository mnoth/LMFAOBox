package lmfaobox;
use Dancer ':syntax';
use Dancer::Plugin::Auth::RBAC;
use Dancer::Plugin::Auth::Twitter;
use Dancer::Plugin::Database;
use Dancer::Plugin::Email;
use Dancer::Plugin::FlashMessage;
use Mail::RFC822::Address qw/valid/;

our $VERSION = '1.0';

auth_twitter_init();

before sub {
    if (not authd() and 
        request->path_info ne '/login' and 
        request->path_info ne '/members/add') {
        request->path_info('/');
    } else {
        if (not defined session('twitter')) {
            session(twitter => config->{'twitter'});
        }
    }
};

get '/' => sub {
    if (not authd()) {
        my @carriers = database->quick_select('carriers', { 1 => 1 });
        template 'index', {
            carriers => \@carriers,
            auth => authd
        };
    } else {
        template 'admin', {
            auth => authd
        };
    }
};

post '/members/add' => sub {
    my $address = params->{'address'};

    if (params->{'carrier'} ne 'Email address') {
        $address =~ tr/\r\n\t A-Za-z()[]\-!@#$%^&*<>\/?//d;
        if (length($address) != 7 or length($address) != 10) {
            $address = "";
        }

        $address .= '@'.database->quick_select('carriers', { name => params->{'carrier'} })->{'suffix'};
    }

    if (valid($address)) {
        database->quick_insert('members', { 
                                    name => params->{'name'}, 
                                    address => $address
                                }) 
           or flash(error => $DBI::errstr);
        flash(info => 'Added your address');
    } else {
        flash(error => 'Invalid address');
    }

    redirect '/';
};

post '/message' => sub {
    foreach my $member (database->quick_select('members', { 1 => 1 } )) {
        email {
            to => $member->{address},
            from => config->{'from_address'},
            message => params->{'message'},
        };
    }

    if (session('twitter_user')) {
        twitter->update(params->{'message'});
    }

    flash(info => 'Message sent');
    redirect '/';
};

get '/members/list' => sub {
    my @members = database->quick_select('members', { 1 => 1 }) or 
        flash(error => $DBI::errstr);

    template 'members', {
        members => \@members,
        auth => authd
    };
};

get '/members/delete/:id' => sub {
    database->quick_delete('members', { id => params->{'id'} }) or flash(error => $DBI::errstr);
    flash(info => "Member deleted");
    redirect '/members/list';
};


get '/carriers/list' => sub {
    my @carriers = database->quick_select('carriers', { 1 => 1 }) or
        flash(error => $DBI::errstr);

    template 'carriers', {
        carriers => \@carriers,
        auth => authd
    };
};

post '/carriers/add' => sub {
    database->quick_insert('carriers', {
                                name => params->{'name'},
                                suffix => params->{'suffix'}
                            }) or flash(error => $DBI::errstr);
    
    flash(info => "Carrier added");
    redirect '/carriers/list';
};

get '/carriers/delete/:name' => sub {
    database->quick_delete('carriers', { name => params->{'name'} }) or flash(error => $DBI::errstr);
    flash(info => "Carrier deleted");
    redirect '/carriers/list';
};

post '/login' => sub {
    my $auth = auth(params->{'user'}, params->{'pass'});
    if ($auth->errors) {
        flash(error => $auth->errors);
    } 

    redirect '/';
};

post '/twitter/connect' => sub {
    if (params->{'twitter'}) {
        session('twitter' => 1);
        redirect auth_twitter_authenticate_url();
    } else {
        session('twitter' => 0);
        redirect '/twitter';
    }
};

get '/twitter' => sub {
    template 'twitter', {
        auth => authd(),
        twitter => session('twitter')
    };
};

true;
