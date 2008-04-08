package WWW::Pastebin::CSSStandardsOrg::Retrieve;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use Devel::TakeHashArgs;
use URI;
use LWP::UserAgent;
use HTML::TokeParser::Simple;
use HTML::Entities;
use base 'Class::Data::Accessor';

__PACKAGE__->mk_classaccessors qw(
    error
    content
    results
    uri
    ua
    id
);

use overload q|""| => sub { shift->content };

sub new {
    my $self = bless {}, shift;
    get_args_as_hash(\@_, \ my %args, { timeout => 30 } )
        or croak $@;

    $args{ua} ||= LWP::UserAgent->new(
        timeout => $args{timeout},
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
    );

    $self->ua( $args{ua} );

    return $self;
}

sub retrieve {
    my ( $self, $id) = @_;

    $self->$_(undef) for qw(error uri id results content);

    $id =~ s{ (?:http://)? \Qpaste.css-standards.org/\E | \s+ }{}xg;

    return $self->_set_error('Paste ID must be numeric')
        if $id =~ /\D/;

    $self->id( $id );

    my $uri = $self->uri( URI->new("http://paste.css-standards.org/$id") );

    my $response = $self->ua->get( $uri );
    $response->is_success
        or return $self->_set_error( $response, 'net' );

    return $self->results( $self->_parse( $response->content ) );
}

sub _parse {
    my ( $self, $content ) = @_;

    my $parser = HTML::TokeParser::Simple->new( \$content );

    my %data;
    my %nav;
    @nav{ qw(level get_name_date  get_content  get_description) } = (0) x 4;
    while ( my $t = $parser->get_token ) {
        if ( $t->is_start_tag('h2') ) {
            @nav{ qw(level get_name_date) } = ( 1, 1 );
        }
        elsif ( $nav{get_name_date} == 1 and $t->is_text ) {
            @data{ qw(name posted_on) }
            = $t->as_is =~ /Posted by (.+?) on (.+)/;
            @nav{ qw(level get_name_date) } = ( 2, 0 );
        }
        elsif ( $t->is_start_tag('textarea')
            and defined $t->get_attr('id')
        ) {
            if ( $t->get_attr('id') eq 'code' ) {
                $nav{get_content} = 1;
            }
            elsif ( $t->get_attr('id') eq 'desc' ) {
                $nav{get_description} = 1;
            }
            $nav{level} = 3;
        }
        elsif ( $nav{get_content} == 1 and $t->is_text ) {
            $data{content} = $t->as_is;
            @nav{ qw(level get_content) } = ( 4, 0 );
        }
        elsif ( $nav{get_description} == 1 and $t->is_text ) {
            $data{desc} = $t->as_is;
            $nav{is_success} = 1;
            last;
        }
    }

    return $self->_set_error("Parser error (level $nav{level}):\n$content")
        unless $nav{is_success};

    for ( values %data ) {
        unless ( defined ) {
            $_ = 'N/A';
            next;
        }

        s/^\s+|\s+$//g;

        unless ( length ) {
            $_ = 'N/A';
            next;
        }

        decode_entities $_;
    }

    unless ( grep { $_ ne 'N/A' } values %data ) {
        return $self->_set_error('This paste does not seem to exist');
    }

    $self->content( $data{content} );

    return \%data;
}

sub _set_error {
    my ( $self, $error, $is_net) = @_;
    if ( defined $is_net ) {
        $self->error( 'Network error: ' . $error->status_line );
    }
    else {
        $self->error( $error );
    }
    return;
}

1;
__END__


=head1 NAME

WWW::Pastebin::CSSStandardsOrg::Retrieve - retrieve pastes from http://paste.css-standards.org/ pastebin

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::Pastebin::CSSStandardsOrg::Retrieve;

    my $paster = WWW::Pastebin::CSSStandardsOrg::Retrieve->new;

    my $results = $paster->retrieve('http://paste.css-standards.org/2904')
        or die $paster->error;

    print "Paste contents:\n$paster\n";

    printf "Posted by %s on %s\nDescription: %s\n",
                @$results{qw(name posted_on desc)};

=head1 DESCRIPTION

The module provides interface to retrieve pastes from
L<http://paste.css-standards.org/> website.

=head1 CONSTRUCTOR

=head2 new

    my $paster = WWW::Pastebin::CSSStandardsOrg::Retrieve->new;

    my $paster = WWW::Pastebin::CSSStandardsOrg::Retrieve->new(
        timeout => 10,
    );

    my $paster = WWW::Pastebin::CSSStandardsOrg::Retrieve->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new yummy juicy
WWW::Pastebin::CSSStandardsOrg::Retrieve
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 timeout

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for retrieving. B<Defaults to:> C<30> seconds.

=head3 ua

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for retrieving, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Pastebin::CSSStandardsOrg::Retrieve>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 retrieve

    my $results_ref = $paster->retrieve('http://paste.css-standards.org/2904')
        or die $paster->error;

    my $results_ref = $paster->retrieve(2904)
        or die $paster->error;

Instructs the object to retrieve a specific paste. Takes one mandatory
argument which can be either paste's number or a full URI to the paste.
On failure returns either C<undef> or an empty list (depending on the
context) and the reason for failure will be available via C<error()> method.
On success returns a hashref with the following keys (if particular
piece of data is not present (e.g. C<name>) it will be set to C<N/A>):

    $VAR1 = {
        'content' => '<!DOCTYPE HTML PUBLIC blah blah',
        'posted_on' => 'Monday, December 11th, 2006 at 14:38',
        'desc' => 'N/A',
        'name' => 'makk'
    };

=head3 content

     { 'content' => '<!DOCTYPE HTML PUBLIC blah blah' }

The C<content> key will contain the actual content of the paste. Also, see
C<content()> method described below which is overloaded.

=head3 posted_on

    { 'posted_on' => 'Monday, December 11th, 2006 at 14:38' }

The C<posted_on> key will contain the date/time when the paste was created.

=head3 desc

    { 'desc' => 'N/A' }

The C<desc> key will contain the description of the paste.

=head3 name

    { 'name' => 'makk' }

The C<name> key will contain the name of the person who created the paste.

=head2 error

    $paster->retrieve(2904)
            or die $paster->error;

On failure the C<retrieve()> method returns either C<undef> or an empty list
(depending on the
context) and the reason for failure will be available via C<error()> method.
Takes no arguments, returns a human parsable message explaining why
C<retrieve()> failed.

=head2 results

    my $last_results = $paster->results;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the exact same hashref last call to C<retrieve()> returned.

=head2 content

    my $paste_content = $paster->content;

    print "Paste contents: $paster\n";

Must be called after a successfull call to C<retrieve()>. Takes no arguments,
returns the content of the paste; in other words, the value of
the C<content> key from the hashref C<retrieve()> returns. B<Note:> this
method is overloaded for this object - you can interpolate the object in
a string to aquire paste's contents:
C<< print "Paste contents: $paster\n"; >>

=head2 uri

    my $paste_uri = $paster->uri;

Must be called after a successfull call to C<retrieve()>. Takes no arguments,
returns a L<URI> object pointing to the retrieved paste irrelevant of
whether C<retrieve()> method was given an ID or URI.

=head2 id

    my $paste_id = $paster->id;

Must be called after a successfull call to C<retrieve()>. Takes no arguments,
returns the ID of retrieved paste irrelevant of
whether C<retrieve()> method was given an ID or URI.

=head2 ua

    my $old_LWP_UA_obj = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

Returns a currently used L<LWP::UserAgent> object used for retrieving
pastes. Takes one optional argument which must be an L<LWP::UserAgent>
object, and the object you specify will be used in any subsequent calls
to C<retrieve()>.

=head1 SEE ALSO

L<LWP::UserAgent>, L<URI>, L<http://paste.css-standards.org>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-cssstandardsorg-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-CSSStandardsOrg-Retrieve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::CSSStandardsOrg::Retrieve

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-CSSStandardsOrg-Retrieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-CSSStandardsOrg-Retrieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-CSSStandardsOrg-Retrieve>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-CSSStandardsOrg-Retrieve>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
