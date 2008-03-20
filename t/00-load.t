#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 18;
my $ID = 2904;
BEGIN {
    use_ok('Carp');
    use_ok('Devel::TakeHashArgs');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::Pastebin::CSSStandardsOrg::Retrieve' );
}

diag( "Testing WWW::Pastebin::CSSStandardsOrg::Retrieve $WWW::Pastebin::CSSStandardsOrg::Retrieve::VERSION, Perl $], $^X" );

my $o = WWW::Pastebin::CSSStandardsOrg::Retrieve->new(timeout => 10);
isa_ok($o, 'WWW::Pastebin::CSSStandardsOrg::Retrieve');
can_ok($o, qw(_set_error  _parse new retrieve     error
    content
    results
    uri
    ua
    id
));

isa_ok($o->ua, 'LWP::UserAgent');

SKIP: {
    my $ret = $o->retrieve($ID);

    unless ( defined $ret ) {
        diag "Got error " . $o->error . " from retrieve() on ID";
        ok( (defined $o->error and length $o->error), 'error()');
        skip "Got error", 6;
    }
    is_deeply( $ret, _make_dump(), 'return from retrieve() matches dump');
    is( $o->uri, "http://paste.css-standards.org/$ID",
        'uri() must return uri to the paste');

    isa_ok( $o->uri, 'URI::http', 'uri() must be a URI object');
    is( $o->id, $ID, '->id() must return ID');
    is( "$o", $o->content, 'overload on content()');
    is( $o->content, $ret->{content}, 'content() and retrieve()->{content}');
    ok( (not defined $o->error), 'error() must be undefined');
}


sub _make_dump {
 return {
          "posted_on" => "Monday, December 11th, 2006 at 14:38",
          "desc" => "N/A",
          "content" => "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\r\n<html lang=\"en\">\r\n<head>\r\n<title></title>\r\n<meta http-equiv=\"content-type\" content=\"text/html; charset=iso-8859-1\">\r\n\r\n<script type=\"text/javascript\">\r\nwindow.onload = function() {\r\n\tvar div = document.createElement('div');\r\n\tdiv.innerHTML = '&nbsp;<script type=\"text/javascript\" defer=\"defer\">alert(\"works\")<\\\\/script>';\r\n\tdocument.body.appendChild(div);\r\n};\r\n</script>\r\n</head>\r\n\r\n<body>\r\n</body>\r\n\r\n</html>",
          "name" => "makk"
        };
}