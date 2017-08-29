<?php
/**
 * Display the results of GO slim gene classification
 */

// dispaly breadcrumb
$nav = array();
$nav[] = l('Home', '/');
$nav[] = l('Gene classification', 'funcat');
$nav[] = t('Gene classification result');
$breadcrumb = '<nav class="nav">' . implode(" > ", $nav) . '</nav><br>';
print $breadcrumb;

  // output gene classification table
  if ($result_table) {

    // download link
    $go_slim_file = '../../' . $tripal_args['output_file'] . '.goslim.tab.txt';
    $download_link = l('Tab-delimited format', $go_slim_file );
    print '<p>Download gene classification result: ' . $download_link . '</p>';

    // table
    $header_data = array_keys($result_table[0]);
	$header_data[] = "Genes";

    $rows_data = array(); 
    foreach ($result_table as $line) 
    {
      $line_html = array();
      $goid = $line[$header_data[0]];
      if ($goid !== 'Unclassified') {
        $go_url = 'http://amigo.geneontology.org/amigo/term/' . $go_id;
        $line_html[0] = l($goid, $go_url, array('attributes' => array('target' => "_blank"))); 
        $line_html[1] = $line[$header_data[1]];
        $line_html[2] = $line[$header_data[2]];
        $line_html[3] = $line[$header_data[3]];
      } else {
        $line_html[0] = $line[$header_data[0]];
        $line_html[1] = 'NA';
        $line_html[2] = 'NA';
        $line_html[3] = $line[$header_data[3]];
      } 

      $line_html[4] = 'NA';
      if ($category) {
        $goid = $line[$header_data[0]];
        if (isset($category[$goid])) {
          $genes = $category[$goid];
          $line_html[4] = '';
          foreach ($genes as $gene) {
            $line_html[4] .= l($gene, 'feature/gene/' . $gene, array('attributes' => array('target' => "_blank"))) . ", ";
          }
        }
      }
      $rows_data[] = $line_html;
    }
 
    $header = array(
      'data' => $header_data,
    );

    $rows = array(
      'data' => $rows_data,
    );


    $variables = array(
      'header' => $header_data,
      'rows' => $rows_data,
      'attributes' => array('class' => 'table'),
    );

    print theme('table', $variables);
  }
  else {
    ?><div>No result</div><?php 
  }
