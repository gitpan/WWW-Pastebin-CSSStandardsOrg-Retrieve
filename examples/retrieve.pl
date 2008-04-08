#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: perl retrieve.pl <paste_ID_or_URI>\n"
    unless @ARGV;

my $ID = shift;

use lib '../lib';
use WWW::Pastebin::CSSStandardsOrg::Retrieve;

my $paster = WWW::Pastebin::CSSStandardsOrg::Retrieve->new;

my $results = $paster->retrieve( $ID )
    or die $paster->error;

print "Paste contents:\n$paster\n";

printf "Posted by %s on %s\nDescription: %s\n",
            @$results{qw(name posted_on desc)};