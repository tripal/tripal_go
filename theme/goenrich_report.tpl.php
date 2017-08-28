<?php
/**
 * Display the results of a go enrichment
 */

// dispaly breadcrumb
$nav = array();
$nav[] = l('Home', '/');
$nav[] = l('GO enrichment', 'goenrich');
$nav[] = t('GO enrichment result');
$breadcrumb = '<nav class="nav">' . implode(" > ", $nav) . '</nav><br>';
print $breadcrumb;

  if ($html_info) {
    // download link
    $go_slim_file = '../../' . $tripal_args['output_file'];
    $download_link = l('HTML Format', $go_slim_file );
    print '<p>Download GO enrichment result: ' . $download_link . '</p>';

    // print result table
    print $html_info;
  }
?>

