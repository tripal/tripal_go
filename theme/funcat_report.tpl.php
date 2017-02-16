<?php
/**
 * Display the results of a BLAST job execution
 */
  // output pathway enrichment table
  if ($result_table) {
    $header_data = array_keys($result_table[0]);

    $rows_data = array(); 
    foreach ($result_table as $line) 
    {
      $line_html = array();
      $line_html[0] = l($line[$header_data[0]],'http://amigo.geneontology.org/amigo/term/'.$line[$header_data[0]], array('attributes' => array('target' => "_blank"))); 
      $line_html[1] = $line[$header_data[1]];
      $line_html[2] = $line[$header_data[2]];
      $line_html[3] = $line[$header_data[3]];
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
