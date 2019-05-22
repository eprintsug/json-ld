# json-ld
Export plugin to transform selected metadata to json linked data to provide structured data for search engine indexing.

## About this plugin

This Export plugin was initially specifically designed for the metadata collected in the [University of Bath Research Data Archive](http://researchdata.bath.ac.uk/).

It can be used as is, but will be most effective if you check the mapping of fields against the specification for datasets structured data linked below.

The plugin was generalized by Mapping EPrints Document Types in the following way:

| schema.org @type | eprints document type |
| ---------------- | ----------------------|
| CreativeWork | default type for all unless it is a thesis, dataset, article, book_section or book |
| Thesis | thesis |
| Dataset | dataset |
| ScholarlyArticle | article |
| Chapter | book_section |
| Book | book |

For exporting a list of eprints from browse views or search results, the results are serialized as a JSON-LD graph.

## Installation

Copy the file to the corresponding location in your EPrints archive (where [name] is the name of your archive).

To make the export appear in the <head> as a JavaScript, add the following line to your archives/[name]/cfg/cfg.d/eprint_render.pl

$links->appendChild( $session->plugin( "Export::JSONLD" )->dataobj_to_html_header( $eprint ) );

## Mapping

| Property | Value |
| -------- | ----- |
| `@context` | http://schema.org/ |
| `@type` | see Mapping EPrints Document Types above |
| `url` | `doi` (formatted to url) if available, otherwise eprint `url` |
| `@id` | `doi` (formatted to url) if available |
| `sameAs` | eprint `url` (if doi used as url) |
| `name` | `title` |
| `description` | `lay_summary` if available, otherwise `abstract` |
| `version` | `version` |
| `keywords` | `keywords` and `subjects` |
| `creator` | `creators` and `corp_creators` |
| `datePublished` | `date` (year only) |
| `publisher` | `publisher` |

## Further information

[Datasets structured data information (Google)](https://developers.google.com/search/docs/data-types/datasets)

[Google structured data testing tool](https://search.google.com/structured-data/testing-tool)
