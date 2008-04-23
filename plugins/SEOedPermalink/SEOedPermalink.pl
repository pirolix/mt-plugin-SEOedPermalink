package MT::Plugin::OMV::SEOedPermalink;
my $DESCRIPTION = <<'PERLHEREDOC';
#   SEOedUrl - Handle the optimized URL for some search engines and guide their web crawler.
#           Programmed by Piroli YUKARINOMIYA
#           Open MagicVox.net - http://www.magicvox.net/home.php
#           @see http://www.magicvox.net/
PERLHEREDOC

use strict;
use Jcode;
use MT::Util qw( encode_php encode_url );
use MT::Template::Context;

use vars qw( $MYNAME $VERSION );
$MYNAME = 'SEOedUrl';
$VERSION = '0.31 DEVEL';

### Register a plugin
use base qw( MT::Plugin );
my $plugin = new MT::Plugin({
        name => $MYNAME,
        version => $VERSION,
        author_name => 'Piroli YUKARINOMIYA',
        author_link => "http://www.magicvox.net/?$MYNAME",
        doc_link => "http://www.magicvox.net/?$MYNAME",
        description => <<HTMLHEREDOC,
Handle the optimized URL for some search engines and guide their web crawler.
Google, Yahoo!, MSN and Baidu are applied.
HTMLHEREDOC
});
MT->add_plugin( $plugin );

sub instance { $plugin; }



### $MTRedirectSEOedUrl$
MT::Template::Context->add_tag( RedirectSEOedUrl => \&redirect_seoed_url );
sub redirect_seoed_url {
    my ( $ctx, $args, $cond ) = @_;

    # original permalink of entry
    my $permalink = MT::Template::Context::_hdlr_entry_permalink(@_)
        or return;
    $permalink = encode_php( $permalink, 'q' );
    # SEDed permalink
    my $seded_permalink = entry_seoed_permalink(@_)
        or return;
    $seded_permalink = encode_php( $seded_permalink, 'q' );

    # Generate PHP codes
    my $php = <<"PHPSOURCECODE";
/************************************************************************
$DESCRIPTION
*/
function SEOedUrl_getPermalink () { return '$permalink'; }
function SEOedUrl_getSEOedPermalink () { return '$seded_permalink'; }
PHPSOURCECODE

    $php .= <<'PHPSOURCECODE';
function SEOedUrl_isSearchEngineCrawler() {
	$ua = $_SERVER['HTTP_USER_AGENT'];
	return preg_match( '/Googlebot\/\d+\.\d+/i', $ua ) // Google
		|| preg_match( '/Yahoo!/i', $ua ) && preg_match( '/Slurp/i', $ua ) // Yahoo!
		|| preg_match( '/^msnbot/i', $ua ) // MSN
		|| preg_match( '/^Baiduspider/i', $ua ) // Baidu
		|| 0;
}

function SEOedUrl_movedPermanently( $url ) {
	header( $_SERVER['SERVER_PROTOCOL']. ' 301 Moved Permanently' );
	header( 'Status: 301 Moved Permanently' );
	header( 'Location: '. $url );
	exit;
}

function SEOedUrl_switch() {
	if( !is_array( $parsed_url = parse_url( SEOedUrl_getPermalink())))
		return;
	$request_uri = preg_replace( '/\?.*$/', '', $_SERVER['REQUEST_URI'] );
	if( SEOedUrl_isSearchEngineCrawler()) {
		if( $request_uri === $parsed_url['path'] )
			SEOedUrl_movedPermanently( SEOedUrl_getSEOedPermalink());
	} else {
		if( $request_uri !== $parsed_url['path'] )
			SEOedUrl_movedPermanently( SEOedUrl_getPermalink());
	}
}
SEOedUrl_switch();
PHPSOURCECODE

    "<?php\n${php}?>";
}

### $MTEntrySEOedPermalink$
MT::Template::Context->add_tag( EntrySEOedPermalink => \&entry_seoed_permalink );
sub entry_seoed_permalink {
    # original permalink
    my $permalink = MT::Template::Context::_hdlr_entry_permalink(@_)
        or return;
    # entry title
    my $title = MT::Template::Context::_hdlr_entry_title(@_)
        or return;
    $title = encode_url( jcode( $title )->utf8 );
    $title =~ s/%20|%2F/_/ig;

    # include the utf8 encoded title string in permalink
    $permalink =~ s!/+$!/$title!;
    $permalink;
}

1;