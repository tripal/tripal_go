
# GO Tool -- Tool for GO enrichment analysis

## Donwload and Installation

Download GO tool module from [github](https://github.com/tripal/tripal_go)
```
cd /var/www/html/youSiteFolder/sites/all/modules/
git clone https://github.com/tripal/tripal_go
```

Install GO tool through "Administration of Modules" of Drupal.

Or install GO tool using command:
```
drush pm-enable tripal_go
```

Install below dependencies
> sudo apt-get install xsltproc (ubuntu)
> [GO::TermFinder](http://search.cpan.org/dist/GO-TermFinder/lib/GO/TermFinder.pm)
> [GO::Parser](http://search.cpan.org/~cmungall/go-perl-0.15/GO/Parser.pm)
> [map2slim](http://search.cpan.org/~cmungall/go-perl-0.15/scripts/map2slim)


## Add GO Annotation File

For some species, the 

Generate [GO Annotation File](http://www.geneontology.org/page/go-annotation-file-formats)(GAF) 
for each genome. Then load the path of GAF to database.
> Home -> Add Content -> GO Database  

For some species, the GAF is avaiable on [Downloads page of GO site](http://www.geneontology.org/page/download-annotations).

## Update GO ontology file

If you GAF file is generated base on the latest version of GO ontology file. 
Please update GO ontology file to latest version. The update process is just 
drop the latest GO ontology file to __obo__ folder of this module. 
 
