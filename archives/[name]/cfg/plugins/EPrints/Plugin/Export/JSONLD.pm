=head1 NAME

EPrints::Plugin::Export::JSONLD

=cut

package EPrints::Plugin::Export::JSONLD;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

use JSON;
sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "JSON LD";
	$self->{accept} = [ 'dataobj/eprint' ];
	$self->{visible} = "all";
	$self->{suffix} = ".js";
	$self->{mimetype} = "application/json; charset=utf-8";

	return $self;
}

sub dataobj_to_html_header
{
	my( $plugin, $dataobj ) = @_;

	my $jsonld = $plugin->{session}->make_doc_fragment;

	my $script_tag = $plugin->{session}->make_element( "script", type => "application/ld+json", id => "jsonLinkedData" );
	my $eprintld = $plugin->convert_dataobj( $dataobj );
	my $json = JSON::to_json( $eprintld );
	$script_tag->appendChild( $plugin->{session}->make_text( $json ) );
	$jsonld->appendChild($script_tag);
  $jsonld->appendChild( $plugin->{session}->make_text( "\n" ) );
	return $jsonld;
}

sub convert_dataobj
{
	my( $plugin, $eprint ) = @_;

	my $dataset = $eprint->{dataset};

	my %jsonldata;

	$jsonldata{'@context'} = 'http://schema.org/';
	$jsonldata{'@type'} = "CreativeWork";
	
	if ( $eprint->exists_and_set( "type" )){
		if ($eprint->get_value( "type" ) eq "thesis" ){
			$jsonldata{'@type'} = "Thesis";
		}
		elsif ($eprint->get_value( "type" ) eq "dataset" ){
			$jsonldata{'@type'} = "Dataset";
		}
		elsif ( $eprint->get_value( "type" ) eq "article" ){
			$jsonldata{'@type'} = "Article";
		}
		elsif ( $eprint->get_value( "type" ) eq "book_section" ){
			$jsonldata{'@type'} = "Chapter";
		}
		elsif ( $eprint->get_value( "type" ) eq "book" ){
			$jsonldata{'@type'} = "Book";
		}
	}

	# The DOI or if not set, URL of the landing page
	if ( $eprint->exists_and_set( "doi" ) ) {
		$jsonldata{url} = 'https://doi.org/' . $eprint->get_value( "doi" );
		$jsonldata{'@id'} = 'https://doi.org/' . $eprint->get_value( "doi" );
		$jsonldata{sameAs} = $eprint->get_url();
	} elsif ( $eprint->exists_and_set( "eprintid" ) ) {
		$jsonldata{url} = $eprint->get_url();
	}

	# The title of the dataset
	if( $eprint->exists_and_set( "title" ) ) {
		$jsonldata{name} = $eprint->get_value( "title" );
	}

	# Prefer the lay summary for Google, if there is one, otherwise the abstract will do
  if( $eprint->exists_and_set( "lay_summary" ) ) {
		$jsonldata{description} = $eprint->get_value( "lay_summary" );
  } elsif( $eprint->exists_and_set( "abstract" ) ) {
    $jsonldata{description} = $eprint->get_value( "abstract" );
  }

	# Include version number
	if( $eprint->exists_and_set( "version" ) ) {
		$jsonldata{version} = $eprint->get_value( "version" );
	}

  
  # Add keywords and subjects as keywords
	my @keywords;

	if ( $eprint->exists_and_set( "keywords" ) ) {
		my $keywords = $eprint->get_value( "keywords" );
		push @keywords, split( ",", $keywords );

	}
	
	if( $eprint->exists_and_set( "subjects" ) ) {
		foreach my $subjectid ( @{$eprint->get_value( "subjects" )} )
		{
			my $subject = EPrints::DataObj::Subject->new( $plugin->{session}, $subjectid );
			next unless( defined $subject ); 
			push @keywords, EPrints::Utils::tree_to_utf8( $subject->render_description() );
		}
	}

	$jsonldata{keywords} = join ( ", ", @keywords ) if scalar @keywords > 0;

	if( $eprint->exists_and_set( "creators" ) )
	{
		my $creators = $eprint->get_value( "creators" );
		if( defined $creators )
		{
			foreach my $creator ( @{$creators} )
			{	
				my %person;
				$person{'@type'} = "Person";
				$person{'@id'} = 'http://orcid.org/' . $creator->{orcid} if defined $creator->{orcid};
				my $name = $creator->{name};
				$person{familyName} = $name->{family} if defined $name->{family};
				$person{givenName} = $name->{given} if defined $name->{given};
				push @{$jsonldata{creator}}, \%person;
			}
		}
	}

	
	if( $eprint->exists_and_set( "date" ) ) {
		my @date = split( "-", $eprint->get_value( "date" ) );
		$jsonldata{datePublished} = $date[0];
	}

	if ( $eprint->exists_and_set( "publisher" ) ) {
		my %publisher;
		$publisher{'@type'} = "Organization";
		$publisher{name} = $eprint->get_value( "publisher" );
		$jsonldata{publisher} = \%publisher;
	}

	return \%jsonldata;
}

sub output_dataobj_html
{
	my( $plugin, $dataobj ) = @_;

	my $json = $plugin->convert_dataobj( $dataobj );

	return $plugin->dataobj_to_html_header( $dataobj );
}

sub output_dataobj
{

	my( $plugin, $dataobj ) = @_;

	my $eprintld = $plugin->convert_dataobj( $dataobj );
	my $json = JSON::to_json( $eprintld );

	return $json;
}

1;