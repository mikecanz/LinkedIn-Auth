package LinkedIn::Auth;
use Dancer ':syntax';
use WWW::LinkedIn qw/get_request_token/;
use HTML::Entities;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/dashboard' => sub {
    my $li = get_client();
    my $profile_xml = $li->request(
                               request_url => 'https://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline)',
                               access_token        => session->{access_token},
                               access_token_secret => session->{access_token_secret},
    );

	my $encoded = encode_entities( $profile_xml );
    template 'dashboard', {xml => $encoded};
};

get '/auth/linkedin' => sub {
    my $li = get_client();

    my $token =
      $li->get_request_token(callback => "http://ec2-23-22-202-118.compute-1.amazonaws.com/auth/linkedin/callback");

    # Save $token->{token} and $token->{secret} for later:
    session request_token        => $token->{token};
    session request_token_secret => $token->{secret};

    template 'login', {url => $token->{url}};
};

# User has returned with token and verifier appended to the URL.
get '/auth/linkedin/callback' => sub {
    my $li = get_client();

    my $access_token = $li->get_access_token(
             verifier             => params->{oauth_verifier},           # <--- This is passed to us in the querystring:
             request_token        => session->{request_token},           # <--- From step 1.
             request_token_secret => session->{request_token_secret},    # <--- From step 1.
                                            );

    if ($access_token) {
        session access_token        => $access_token->{token};
        session access_token_secret => $access_token->{secret};

        redirect '/dashboard';
    } else {
        redirect '/auth/linkedin';
    }

};

sub get_client
{
    my $li = WWW::LinkedIn->new(
                                consumer_key    => '<YOUR_API_KEY>',        # Your 'API Key'
                                consumer_secret => '<YOUR_SECRET_KEY>',    # Your 'Secret Key'
                               );
}

true;
