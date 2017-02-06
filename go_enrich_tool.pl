#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use GO::TermFinder;
use GO::AnnotationProvider::AnnotationParser;
use GO::OntologyProvider::OboParser;
use GO::View;
use GO::TermFinderReport::Html;
use GO::Utils::File		qw (GenesFromFile);
use GO::Utils::General qw (CategorizeGenes);
use Getopt::Std;

my $usage = qq'
USAGE: $0 -a process -t gene -p 0.05 -c simulation -m no gene_list.txt go_associate.obo output.html 

	-a aspect: (F)unction, (P)rocess, (C)omponent
	-p p-value cutoff: [default: 0.05]
	-c correction method: bonferroni, simulation, (1)FDR 
	-m display picture showing GO DAG [yes, no]
	-t type of input gene [unigene, gene] default: gene
	-r DRUPAL_ROOT ( example: /var/www/html/tripal)
';
my %options;
getopts('a:p:c:m:t:r:', \%options);

print $usage." no input\n" and exit unless scalar @ARGV == 3;

if (defined $options{'a'} && ($options{'a'} eq 'F' || $options{'a'} eq 'P' || $options{'a'} eq 'C')) { } 
else { print $usage." aspect\n" and exit; }

if (defined $options{'p'} && $options{'p'} > 0 && $options{'p'} < 1) { }
else { print $usage." pvalue\n" and exit; }

if (defined $options{'c'} && ($options{'c'} eq 'bonferroni' || $options{'c'} eq 'simulation' || $options{'c'} eq 'FDR')) { }
else { print $usage." correction\n" and exit; }

if (defined $options{'t'} && ($options{'t'} eq 'gene' || $options{'t'} eq 'unigene')) { }
else { print $usage." type of input list\n" and exit; }

my $drupal_root;
if (defined $options{'r'}) { $drupal_root = $options{'r'}; }
else { print $usage." drupal root for image\n" and exit; }

my $aspect = $options{'a'};
my $pvalue = $options{'p'};
my $correct = $options{'c'};
my $picture = $options{'m'} if defined $options{'m'};
my $type = $options{'t'};

# set tmp folder for image
my $tmp_url = "/sites/default/files/tripal/tripal_goenrich";
my $tmp_fdr = $drupal_root.$tmp_url."/";

my ($gene_list, $associate_file, $output_html) = @ARGV;

# put gene list to array
my %gene_uniq;
open(F1, $gene_list) || die $!;
while(<F1>) {
	chomp;
	$gene_uniq{$_} = 1;	
}
close(F1);
my @genes = sort keys %gene_uniq;

# main
my $url = "/feature/$type/<REPLACE_THIS>";
my $ontology_file = $FindBin::RealBin.'/obo/go-basic.obo';
my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => $ontology_file, aspect => $aspect);
my $annotation = GO::AnnotationProvider::AnnotationParser->new(annotationFile=>$associate_file);
my $totalNumGenes = $annotation->numAnnotatedGenes;

my $termFinder = GO::TermFinder->new(
					annotationProvider => $annotation,
					ontologyProvider => $ontology,
					totalNumGenes => $totalNumGenes,
					aspect => $aspect
				 );

my $report  = GO::TermFinderReport::Html->new();
    
my @pvalues;
    
if ($correct eq 'FDR') {
	@pvalues = $termFinder->findTerms(genes => \@genes,
		calculateFDR => 1);
}
else {
	@pvalues = $termFinder->findTerms(genes => \@genes,
		correction => $correct,
		calculateFDR => 0);
}
 
my $goView = GO::View->new(-ontologyProvider => $ontology,
                    -annotationProvider => $annotation,
                    -termFinder => \@pvalues,
                    -aspect => $aspect,
                    -configFile => "/home/web/GO/GoView.conf",
                    -imageDir => $tmp_fdr,
                    -imageLabel => "Cucurbit Genomics Database",
                    -nodeUrl => "http://amigo.geneontology.org/amigo/term/<REPLACE_THIS>",
                    -geneUrl => $url,
                    -pvalueCutOff => $pvalue);

my $imageFile;

=head

ANNOTATION      GO::AnnotationProvider::AnnotationParser=HASH(0x210be18)
ASPECT  P
DESCENDANT_GOID_ARRAY_REF       ARRAY(0x2cbe500)
GENE_NAME_HASH_REF_FOR_GOID     HASH(0x2cbe518)
GENE_URL        /feature/gene/<REPLACE_THIS>
GOID    GO:0008150
GO_URL  http://amigo.geneontology.org/amigo/term/<REPLACE_THIS>
GRAPH   GraphViz=HASH(0x106f4488)
HEIGHT_DISPLAY_RATIO    0.8
IMAGE_DIR       /var/www/html/icugiold/ICuGI/tmp/
IMAGE_FILE      /var/www/html/icugiold/ICuGI/tmp/GOview.31979.png
IMAGE_LABEL     testLable
IMAGE_URL       ./GOview.31979.png
MAX_NODE        30
MAX_TOP_NODE_TO_SHOW    6
MIN_MAP_HEIGHT_FOR_TOP_KEY      600
MIN_MAP_WIDTH   350
MIN_MAP_WIDTH_FOR_ONE_LINE_KEY  620
ONTOLOGY        GO::OntologyProvider::OboParser=HASH(0x210be30)
PVALUE_CUTOFF   0.05
PVALUE_HASH_REF_FOR_GOID        HASH(0x2cbe530)
TERM_FINDER     ARRAY(0x2d0b418)
TERM_HASH_REF_FOR_GOID  HASH(0x124bb0a0)
TREE_TYPE       down
WIDTH_DISPLAY_RATIO     0.8

=cut

if ($goView->graph) {
	$imageFile = $goView->showGraph;
	$imageFile =~ s/.*\///;
	$imageFile =~ s/GOview/goPath/;
}

GenerateHTMLFile($goView->imageMap, \@pvalues, scalar($termFinder->genesDatabaseIds));

# ============= subroutine =============

sub GenerateHTMLFile 
{
	my ($map, $pvaluesRef, $numGenes) = @_;

    open(HTML, ">$output_html") || die $!;
        
	my $numRows = $report->print(pvalues => $pvaluesRef,
		aspect => $aspect,
		numGenes => $numGenes,
		totalNum => $totalNumGenes,
		pvalueCutOff => $pvalue,
		fh => \*HTML,
		geneUrl => $url,
		goidUrl => "http://amigo.geneontology.org/amigo/term/<REPLACE_THIS>"
	);
        
	if ($numRows == 0) {
		print HTML "<p>There were no GO nodes exceeding the p-value cutoff of $pvalue</p>\n"; 
	}
	print HTML "<br>";
     
    # the map info does not generated in ubuntu server   
	#if (defined $map && $picture eq "yes") {
	#	$map =~ s/\.\//\/icugiold\/ICuGI\/tmp\//;
	#	$map =~ s/SHAPE=/target=_blank SHAPE=/g;
	#	$map =~ s/ title=""//g;
	#	$map =~ s/<img /<img border=0 /;
	#	print HTML $map;
	#}
   
	if ($picture eq "yes") {
		my $image_html = qq'
		<a href="$tmp_url/$imageFile" target=_blank><img class="img-responsive" src="$tmp_url/$imageFile"></a>
		';

		print HTML $image_html;
    }
    close(HTML);

	parse_html($output_html);
}

=head2
 parse the HTML generate by GO::TermFinder
 the TermFinderReport Html generate some error for the html output
 so we need to parse the html output to generate correct result 
=cut
sub parse_html
{
	my $input_file = shift;

	# save html content to vars
	my $html = '';
	open(FH, $input_file) || die $!;
	while(<FH>) 
	{
		my @a = split(//, $_);
		foreach my $a (@a) 
		{
			if ($a eq '>') {
				$html.= $a."\n";
			} else {
				$html.= $a;
			}
		}
	}
	close(FH);

	# parse html
	# skip the 1st line with <a name="table" />
	# replace target="infowin" to target="_blank"
	# href="http://amigo.geneontology.org/amigo/term/GO:0048827"
	my $html2 = '';
	my @b = split(/\n/, $html);
	for(my $i=1; $i<@b; $i++) {
		my $char = $b[$i];
		$char =~ s/infowin/_blank/ig;

		if ($char =~ m/^<table/) {
			$char = "<table align=\"center\" class=\"table table-striped\">"
 		}
		
		if ($char =~ m/amigo\.geneontology\.org\/amigo\/term\/(\S+)"/) {
			my $go_id = $1;
			$char = $char.$go_id."<br>".$b[$i+1];
			$i++;
		}
		$html2.=$char."\n";
	}

	# write final html info to the input html file
	open(OUT, ">$input_file") || die $!;
	print OUT $html2."\n";
	close(OUT);	
}

