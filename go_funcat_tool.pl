#!/usr/bin/perl

=head
 GOtool.pl -- tools for GO analysis
 Yi Zheng
=cut

use strict;
use warnings;
use diagnostics;

use IO::File;
use FindBin;
use GO::TermFinder;
use GO::AnnotationProvider::AnnotationParser;
use GO::OntologyProvider::OboParser;
use GO::TermFinderReport::Text;
use GO::Utils::File    qw (GenesFromFile);
use GO::Utils::General qw (CategorizeGenes);
use Getopt::Std;

my $version = 0.1;
my $debug = 0;

my %options;
getopts('a:b:c:d:e:f:g:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:h', \%options);
go_slim(\%options, \@ARGV);

# ==========================
# --- kentnf: subroutine ---
# ==========================
=head2
 go_slim: perform GO slim analysis
=cut
sub go_slim
{
	my ($options, $files) = @_;

	my $usage = qq'
USAGE: $0 [options] input_list GO_associate_file output_prefix

  -a aspect: (F)unction, (P)rocess, (C)omponent 

* the list of ID must be a subset of background GO_associate_file.

';
	#################################################################
	# init setting and checking input files				#
	#################################################################

	print $usage and exit unless @$files == 3;
	my $listID = $$files[0];
	my $associate_in = $$files[1];
	my $output = $$files[2];

	die "[ERR]list not exit\n" unless -s $listID;	
	die "[ERR]GAF not exit\n" unless -s $associate_in;

	my $out_slim = $output.".goslim.txt";
	my $out_slim_tab = $output.".goslim.tab.txt";

	# go-basic.obo.gz  goslim_plant.obo.gz
	my $gene_ontology_obo = $FindBin::RealBin."/obo/go-basic.obo";
	my $plant_go_slim     = $FindBin::RealBin."/obo/goslim_plant.obo";

	my $map2slim_script   = $FindBin::RealBin."/bin/map2slim";
	$gene_ontology_obo = $$options{'n'} if defined $$options{'n'};
	$plant_go_slim     = $$options{'s'} if defined $$options{'s'};

	foreach my $f ( ($gene_ontology_obo, $plant_go_slim, $map2slim_script) ) {
		die "[ERR]file not exit: $f\n" unless -s $f;
	}

	my $aspect = 'P';
	if ( defined $$options{'a'} ) {
		if (defined $options{'a'} && ($options{'a'} eq 'F' || $options{'a'} eq 'P' || $options{'a'} eq 'C')) {
			$aspect = $options{'a'};
		}
	}

	#####################################
	# main								#
	#####################################

	# put ID to hash
	my %ID;
	my $fh = IO::File->new($listID) || die "Can not open list IDs file $listID $!\n";
    while(<$fh>){
		chomp;
		$_ =~ s/\s//ig;
		$ID{$_} = 1;
	}
    $fh->close;

	# create temp associate_in base on $listID and associate_in;
	my $associate_temp = $listID.".temp.asso";

	my $out = IO::File->new(">".$associate_temp) || die "Can not open file $associate_temp\n";
	my $in  = IO::File->new($associate_in)   || die "Can not open file $associate_in\n";
	while(<$in>) {   
		chomp;
		next if $_ =~ m/^#/;
		next if $_ =~ m/^!/;
		my @a = split(/\t/, $_);
		if (defined $ID{$a[1]} && $a[8] eq $aspect) {
			print $out $_."\n";
		}
	}
	$in->close;
    $out->close;

	go_slim_analysis($map2slim_script, $associate_temp, $plant_go_slim, $gene_ontology_obo, \%ID, $out_slim, $out_slim_tab);
}

# ===============================================================
# kentnf : go_slim : subroutine					
# ===============================================================

=head2
 go_slim_analysis
=cut
sub go_slim_analysis
{
	my ($map2slim_script, $associate_in, $plant_go_slim, $gene_ontology_obo, $ID, $out_slim, $out_slim_tab) = @_;

	# perform GO slim analysis using map2slim script
	my $temp_file = $associate_in.".slim.gaf";
	my $cmd_map2slim = "$map2slim_script $plant_go_slim $gene_ontology_obo $associate_in > $temp_file";
	print $cmd_map2slim."\n";
	system($cmd_map2slim) && die "[ERR][CMD]: $cmd_map2slim\n";

	my %GO_gid;	# key: GO ID \t gene id; value: 1;
	%GO_gid = map2slim_result_to_hash($temp_file, $out_slim);

	#########################################################
	# convert GO_gid hash to GO_num hash			#
	#########################################################
	my %GO_num;     # key: GO ID; value: number of genes
	foreach my $gg (sort keys %GO_gid) {
       	my ($gene_id, $go_id) = split(/\t/, $gg);
        if (defined $GO_num{$go_id}) {
			$GO_num{$go_id}++;
		} else {
			$GO_num{$go_id} = 1;
		}
		delete $$ID{$gene_id};
	}

	#########################################################
	# put go slim annotation to hash			#
	#########################################################
	my %GO_name;            # key: GO ID; value: GO name
	my %GO_namespace;       # key: GO ID; value: GO namespace
	my ($GO_name, $GO_namespace) = load_plant_go_slim($plant_go_slim);

	%GO_name = %$GO_name; %GO_namespace = %$GO_namespace;

	foreach my $a (sort keys %GO_name)
	{
		#print "$a\t$GO_name{$a}\n";
	}


	#########################################################
	# print the output result				#
	#########################################################
	my $out = IO::File->new(">$out_slim_tab") || die "Can not open file $out_slim_tab $!\n";
	print $out "GO term ID\tDescription\tCategory\t# of genes\n";
	# outut result table
	foreach my $id (sort keys %GO_num) {
		if ($GO_num{$id} && $GO_namespace{$id} && $GO_name{$id})
		{
			my $go_namespace;
			$go_namespace = 'P' if $GO_namespace{$id} eq 'biological_process';
			$go_namespace = 'F' if $GO_namespace{$id} eq 'molecular_function';
			$go_namespace = 'C' if $GO_namespace{$id} eq 'cellular_component';
			
        	print $out $id."\t".$GO_name{$id}."\t".$GO_namespace{$id}."\t".$GO_num{$id}."\n";
		}
		else
		{
			print "Error\t$id\t$GO_num{$id}\n";
		}
	}
	# output undetermined 
	if (scalar(keys(%$ID)) > 0) {
		my $uncat = scalar(keys(%$ID));
		print $out "Unclassified\t\t\t$uncat\n";
	}
	$out->close;
}

=head1 
 map2slim_result_to_hash -- map2slim output to hash				
 output gene and corresponding GO info
=cut
sub map2slim_result_to_hash
{
	my ($map2slim_result, $output) = @_;;

	my %GO_gid = ();

	my ($go_id, $gene_id);

	my $out = IO::File->new(">$output") || die "Can not open output goslim: $output $!\n";
	my $fh = IO::File->new($map2slim_result) || die "Can not open map2slim result file: $map2slim_result\n";
	while(<$fh>)
	{
		chomp;
		my @a = split(/\t/, $_);
		($gene_id, $go_id) = ($a[1], $a[4]);

		# prase the output of map2slim
		if ($go_id ne "GO:0008150" && $go_id ne "GO:0005575" && $go_id ne "GO:0003674")
		{
			unless (defined $GO_gid{$gene_id."\t".$go_id})
			{
				$GO_gid{$gene_id."\t".$go_id} = 1;
				print $out $gene_id."\t".$go_id."\n";
			}
		}
	}
	$fh->close;
	$out->close;

	return %GO_gid;
}

=head1 
 load_plant_go_slim -- load plant go slim info to hash
 %go_name	# key: GO ID; value: GO name
 %go_namespace	# key: GO ID; value: GO namespace
=cut
sub load_plant_go_slim
{
	my $plant_go_slim = shift;

	my %GO_name; my %GO_namespace;

	my ($i, $j, $id, $name, $namespace);

	my $fh;
	if ($plant_go_slim =~ m/\.gz$/) {
		open($fh , "-|", "gzip -cd $plant_go_slim") || die $!;
	} else {
		open($fh, $plant_go_slim) || die $!;
	}

	while(<$fh>)
	{
		chomp;
		if ($_ =~ m/\[Term\]/ || $_ =~ m/\[Typedef\]/ )
		{
			if ($id && $name && $namespace)
			{
				$GO_name{$id} = $name;
				$GO_namespace{$id} = $namespace;
				$i++;
			}
		
			if ($_ =~ m/\[Term\]/) { $j++; }
			$id = ""; $name = ""; $namespace = "";
		}
		elsif ($_ =~ m/^id:\s(.*)/)
		{
			$id = $1;
		}
		elsif ($_ =~ m/^name:\s(.*)/)
		{
			$name = $1;
		}
		elsif ($_ =~ m/^namespace:\s(.*)/)
		{
			$namespace = $1;
		}
		else
		{
			next;
		}
	}
	$fh->close;

	# chech the number GO ID and GO name
	if ($i == $j) {
		#print "There are $i annotation in GO annotation $plant_go_slim\n";
	} else {
		print "There are $i annotation in GO annotation $plant_go_slim\n".
		      "But there are $j term in GO annotation $plant_go_slim\n";
	}

	return (\%GO_name, \%GO_namespace);
}

=head2 
 compute_pvalue: compute p-value for enrichment analysis
=cut
sub compute_pvalue
{
	my ($num_a, $num_b, $tab_a, $tab_b) = @_;

	# num in tab_b to hash
	my %hash_b;
	my $fh = IO::File->new($tab_b) || die "Can not open goslim table all $tab_b $!\n";
	while(<$fh>)
	{
		chomp;
		my @a = split(/\t/, $_);
		$hash_b{$a[0]} = $a[1];
	}
	$fh->close;

	my $tab_t = $tab_a."_temp";
	my $out = IO::File->new(">".$tab_t) || die "Can not open temp goslim table for list with p-value $tab_t $!\n";
	my $in  = IO::File->new($tab_a) || die "Can not open goslim table for list $tab_a $!\n";
	while(<$in>)
	{
		chomp;
		my ($go_id, $num_a_sub, $namespace, $name) = split(/\t/, $_);

		my ($population, $good, $bad, $sample, $select);

		$population = $num_b;
		$good = $hash_b{$go_id};
		$bad  = $num_b - $hash_b{$go_id};

		$sample = $num_a;
		$select = $num_a_sub;

		my $pvalue = hypergeom1($good, $bad, $sample, $select);

		print $out "$go_id\t$num_a_sub\t$num_a\t$hash_b{$go_id}\t$num_b\t$pvalue\t$namespace\t$name\n";
	}
	$in->close;
	$out->close;

	# adjust P value to Q value using R
	my $R_QV =<< "END";
a<-read.table("$tab_t", header = FALSE, sep = "\t")
p<-a[,6]
q<-p.adjust(p, method="BH", n=length(p))
write.table(q, file="qvalue.temp", sep = "\t", row.names = FALSE, col.names = FALSE)
END

	open R,"|/usr/bin/R --vanilla --slave" or die $!;
	print R $R_QV;
	close R;

	# combine the table into on
	my $tab_p = $tab_a."_pvalue";
	my $outp = IO::File->new(">".$tab_p) || die "Can not open goslim table for list with p-value $tab_p $!\n";
	my $in1 = IO::File->new($tab_t) || die "Can not open temp goslim table for list with p-value $tab_t $!\n";
	my $in2 = IO::File->new("qvalue.temp") || die "Can not open temp q-value $!\n";
	while(<$in1>)
	{
		chomp;
		my ($go_id, $num_a_sub, $a, $num_b_sub, $b, $pvalue, $namespace, $name) = split(/\t/, $_);
		my $qvalue = <$in2>;
		chomp($qvalue);
		unless($qvalue) { die "Error at qvalue file qvalue.temp $!\n"; }
		print $outp "$go_id\t$num_a_sub\t$a\t$num_b_sub\t$b\t$pvalue\t$qvalue\t$namespace\t$name\n";
	}
	$in1->close;
	$in2->close;
	$outp->close;
	unlink($tab_t);
	unlink("qvalue.temp");
}

=head2
 hypergeom1: hypergeometric distribution
=cut
sub hypergeom1 
{

 	# There are m "bad" and n "good" balls in an urn.
	# Pick N of them. The probability of i or more successful selections:
	# (m!n!N!(m+n-N)!)/(i!(n-i)!(m+i-N)!(N-i)!(m+n)!)
	# $m+n pop  $n successful
	# $N sample $i successful
	my ($n, $m, $N, $i) = @_;
    	my $loghyp1 = logfact1($m) +logfact1($n)+logfact1($N)+logfact1($m+$n-$N);
	my $loghyp2 = logfact1($i)+logfact1($n-$i)+logfact1($m+$i-$N)+logfact1($N-$i)+logfact1($m+$n);
	return exp($loghyp1 - $loghyp2);
}

sub logfact1 
{
	my $x = shift;
	my $ser = (   1.000000000190015
                + 76.18009172947146   / ($x + 2)
                - 86.50532032941677   / ($x + 3)
                + 24.01409824083091   / ($x + 4)
                - 1.231739572450155   / ($x + 5)
                + 0.12086509738661e-2 / ($x + 6)
                - 0.5395239384953e-5  / ($x + 7) );
	my $tmp = $x + 6.5;
	($x + 1.5) * log($tmp) - $tmp + log(2.5066282746310005 * $ser / ($x+1));
}

=head1 
 get_total_gene_num: get total gene number from input associate file
=cut
sub get_total_gene_num
{
	my $associate = shift;
	my %gid;
	my $fh = IO::File->new($associate) || die "Can not open input associate file: $associate \n";
	while(<$fh>)
	{
	    chomp;
	    unless ($_ =~ m/^!/)
	    {
		my @a = split(/\t/, $_);
		$gid{$a[1]} = 1;
	    }
	}
	$fh->close;	
	my $totalNum = scalar(keys(%gid));
	return $totalNum;
}

