<?php
/**
 * Display the results of a BLAST job execution
 */
  // output pathway enrichment table

  if ($result_table) {
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
        $line_html[3] = 'NA';
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
