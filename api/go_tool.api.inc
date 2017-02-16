<?php

/**
 * @file
 * Contains more generally applicable functions as well as some meant to help developers
 * Plug-in to the GO Tool functionality
 */

/**
 * Returns a list GAF DB options
 *
 * @return
 *   An array where the nid is the key and the value is array
 *   array: 
 *      1 the human-readable name of the option
 *      2 path
 *      3 type
 *      4 example id
 */
function get_gaf_db_options() {
  global $user;

  // Use the Entity API to get a list of GAF Nodes to load
  // We use this function in order respect node access control so that
  // administrators can use this module in combination with a node access module
  // of their choice to limit access to specific BLAST databases.
  $query = new EntityFieldQuery();
  $query->entityCondition('entity_type', 'node')
    // Restrict to BLASTDB nodes.
    ->entityCondition('bundle', 'gaf')
    // Restrict to Published nodes.
    ->propertyCondition('status', 1)
    // Restrict to nodes the current user has permission to view.
    ->addTag('node_access');
  $entities = $query->execute();


  // Get all BlastDB nodes
  $nodes  = node_load_multiple(array_keys($entities['node']));

  $options = array();
  foreach ($nodes as $node) {
    if ( isset($node) && isset($node->db_dbtype) && isset($node->db_name) && isset($node->db_path) && isset($node->db_example_id) ) {
      $options[$node->nid] = array(
        $node->db_name,
        $node->db_path,
        $node->db_dbtype,
        $node->db_example_id,
      );
    }
  }
  asort($options);

  return $options;
}

/** 
 * Run GO enrichment job ()
 *
 */
function run_goenrich_tripal_job($program, $gene_list, $go_annotation, $output_file, $options, $job_id = NULL) {

  print "\nExecuting $program\n\n";
  print "Gene List: $gene_list\n";
  print "GO Annotation File: $go_annotation\n";
  print "Results File: $output_file\n";

  // Note: all variables are escaped (adds single quotes around their values) for security reasons.
  $goenrich_cmd = escapeshellarg($program);
  if (!empty($options)) {
    foreach ($options as $opt => $val) {
      $val = trim($val);
      if (!empty($val)) {
        print "\t$opt: $val\n";
        // We want to escape all the option values since they were supplied via
        // user input. These values should also have been checked in the
        // advanced form _validate functions but this adds an extra layer of
        // protection.
        $goenrich_cmd .= ' -' . escapeshellarg($opt) . ' ' . escapeshellarg($val);
      }
    }
  }
  $goenrich_cmd.= ' -r ' . DRUPAL_ROOT;
  $goenrich_cmd.= ' '. escapeshellarg($gene_list) . ' ' . escapeshellarg($go_annotation) . ' ' . escapeshellarg($output_file);

  // Setting the value of threads by admin page
  print "\nExecuting the following GO enrichment command:\n" . $goenrich_cmd . "\n";

  system($goenrich_cmd); # just print command , do not run it 

  if (!file_exists($output_file)) {
    tripal_report_error(
      'go_tool',
      TRIPAL_ERROR,
      "GO enrichment did not complete successfully as is implied by the lack of output file (%file). The command run was @command",
      array('%file' => $output_file, '@command' => $goenrich_cmd),
      array('print' => TRUE)
    );
    return FALSE;
  }

  print "done";
}

/** 
 * Run GO slim gene classification job ()
 *
 */
function run_funcat_tripal_job($program, $gene_list, $go_annotation, $output_file, $options, $job_id = NULL) {

  print "\nExecuting $program\n\n";
  print "Gene List: $gene_list\n";
  print "GO Annotation File: $go_annotation\n";
  print "Results File: $output_file\n";

  // Note: all variables are escaped (adds single quotes around their values) for security reasons.
  $funcat_cmd = escapeshellarg($program);
  if (!empty($options)) {
    foreach ($options as $opt => $val) {
      $val = trim($val);
      if (!empty($val)) {
        print "\t$opt: $val\n";
        // We want to escape all the option values since they were supplied via
        // user input. These values should also have been checked in the
        // advanced form _validate functions but this adds an extra layer of
        // protection.
        $funcat_cmd .= ' -' . escapeshellarg($opt) . ' ' . escapeshellarg($val);
      }
    }
  }
  // $funcat_cmd.= ' -r ' . DRUPAL_ROOT;
  $funcat_cmd.= ' '. escapeshellarg($gene_list) . ' ' . escapeshellarg($go_annotation) . ' ' . escapeshellarg($output_file);

  // Setting the value of threads by admin page
  print "\nExecuting the following GO gene classification command:\n" . $funcat_cmd . "\n";

  system($funcat_cmd); # just print command , do not run it 

  $output_tab = $output_file . ".goslim.tab.txt";
  if (!file_exists($output_tab)) {
    tripal_report_error(
      'go_tool',
      TRIPAL_ERROR,
      "GO slim gene classification did not complete successfully as is implied by the lack of output file (%file). The command run was @command",
      array('%file' => $output_tab, '@command' => $funcat_cmd),
      array('print' => TRUE)
    );
    return FALSE;
  }

  print "done";
}

