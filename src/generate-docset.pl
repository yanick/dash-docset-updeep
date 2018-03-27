#!/usr/bin/perl 

use 5.20.0;

use strict;
use warnings;

use Dash::Docset::Generator;
use Markdent::Simple::Document;
use Path::Tiny;
use Web::Query::LibXML;
use List::Util qw/ pairs /;

my $docset = Dash::Docset::Generator->new( 
    name => "Updeep",
    platform_family => 'updeep',
    output_dir => '.',
    homepage => 'https://github.com/substantial/updeep',
);

my $readme =  path('updeep/README.md')->slurp ;

# remove badges 
$readme =~ s/^\[!\[.*$//mg;

$readme =~ s/```js/```javascript/gm;

my $index = wq(Markdent::Simple::Document->new->markdown_to_html(
    title => '',
    markdown => $readme,
    dialects => [ 'GitHub' ],
));

$index->find('head')->append(<<'END');
    <link href="assets/github-style.css" rel="stylesheet"></link>
    <link href="assets/prism.css" rel="stylesheet">
    </link><script src="assets/prism.js"></script>
END

my %files = ( 'index.html' => $index );

# process all the schema objects
0 and $index->find('h4')->each(sub{
    warn $_->text;
        
    return unless $_->text =~ / ^ (.*) \s+ Object \s* $ /x;
    my $file = $1.'.html' =~ s/ /_/gr;

    my $t = $_->text;
    $_->find('a')->attr( 'docset-type' => 'Object' );
    $_->find('a')->attr( 'docset-name' => $t );

    my $content = wq('<html><head/><body/></html>');

    $files{$file} = $content;

    $content->find('body')->append($_)->append($_->next_until('h4'));
    $_->next_until('h4')->remove;
    $_->remove;

    $content->find( 'a' )->each( sub {
        my $ref = $_->attr('name') or return;
        my $xpath = "//a[\@href='#$ref']";

        $_->find(\$xpath)->each(sub{
            $_->attr('href', $file . $_->attr('href') );
        }) for values %files;
    });


});

{
    # process the functions section
    
    my $functions = new_doc();
    $files{'functions.html'} = $functions;

    my $x = $index->find('h3')->filter(sub{ $_->text =~ /^u/ })->each(sub{
        my $anchor = wq( '<a/>');

        my $name = $_->text;
        $name =~ s/^u\.//; $name =~ s/\(.*//; $name =~ s/\W//g;
        $name = 'u' unless $name =~ /\w/;
    
        $anchor->attr( 'docset-type' => 'Function' );
        $anchor->attr( 'docset-name' => $name );

        $_->prepend( $anchor );
        $functions->find('body')->append($_);
        $functions->find('body')->append($_->next_until('h1,h2,h3'));
        $_->next_until('h1,h2,h3')->and_back->detach;
    });

}

$docset->add_doc( $_->[0], $_->[1] ) for pairs %files;
$docset->add_asset( 'assets/github-style.css' );
$docset->add_asset( 'assets/prism.js' );
$docset->add_asset( 'assets/prism.css' );

$docset->generate;


sub new_doc {
    wq(<<'END');
    <html><head>
<link href="assets/github-style.css" rel="stylesheet"></link>
<link href="assets/prism.css" rel="stylesheet">
</link><script src="assets/prism.js"></script>
</head><body/></html>
END
}

