package lmfaobox;
use Dancer ':syntax';
use Dancer::Plugin::Auth::RBAC;
use Dancer::Plugin::Database;
use Dancer::Plugin::Email;
use Dancer::Plugin::FlashMessage;

use Data::Dumper;

use 5.012;

our $VERSION = '1.0';

before sub {
    if (not authd() and request->path_info ne '/login') {
        request->path_info('/');
    }
};

get '/' => sub {
    my @carriers = database->quick_select('carriers', { 1 => 1 });
    template 'index', {
        carriers => \@carriers,
        auth => authd
    };
};

post '/members/add' => sub {
    my $address = params->{'address'};

    if (params->{'carrier'} ne 'Email address') {
        $address .= '@';
        $address .= database->quick_select('carriers', { name => params->{'carrier'} })->{'suffix'};
    }

    database->quick_insert('members', { 
                                name => params->{'name'}, 
                                address => $address
                            }) 
       or flash(error => $DBI::errstr);

    flash(info => 'Added your address');
    redirect '/';
};

post '/message' => sub {
    foreach my $member (database->quick_select('members', { 1 => 1 } )) {
        email {
            to => $member->{address},
            from => 'freshmen@csh.rit.edu',
            message => params->{'message'},
        };
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
        say $auth->errors;
    } else {
        redirect '/';
    }
};

true;
