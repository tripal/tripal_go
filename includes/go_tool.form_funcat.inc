<?php

/**
 * @file
 *
 */

/**
 * generate form for go slim gene classification.
 */
function go_tool_funcat_form($form, $form_state) {

  //* choose GO dataset
  //*   An array where the nid is the key and the value is array
  //*   array: 
  //*      1 the human-readable name of the option
  //*      2 path
  //*      3 type
  //*      4 example id
  $gaf_db = get_gaf_db_options();

  $db_type = array();
  $db_expid = array();
  $options = array(
    'SELECT_DB' => 'Select a Dataset',
  );

  foreach ($gaf_db as $nid => $gaf_array) {
    $options[$gaf_array[1]]  = $gaf_array[0];
    $db_type[$gaf_array[1]]  = $gaf_array[2];
    $db_expid[$gaf_array[1]] = $gaf_array[3];
  }

  // pass these array for ajax
  $form['#db_type']  = $db_type;
  $form['#db_expid'] = $db_expid;
  //store GAF type, gene or unigene
  $form['gaf_type'] = array(
    '#type' => 'hidden',
    '#value' => 'gene'
  );

  $form['SELECT_GO_DATASET'] = array(
    '#type' => 'select',
    '#title' => t('Dataset:'),
    '#options' => $options,
    '#default_value' => 'SELECT_DB',
    '#ajax' => array(
      'callback' => 'ajax_go_tool_funcat_example_id_callback',
      'wrapper'  => 'id-textarea',
      'method'   => 'replace',
      'effect'   => 'fade',
    ),
  );

  // NUCLEOTIDE QUERY
  //.........................
  $form['query'] = array(
    '#type' => 'fieldset',
    '#title' => t('Enter the list of IDs.'),
    '#collapsible' => FALSE,
    '#collapsed' => FALSE,
  );

  // Checkbox to show an example.
  $form['query']['example_id'] = array(
    '#type' => 'checkbox',
    '#title' => t('Show an Example ID'),
    '#prefix' => '<span style="float: right;">',
    '#suffix' => '</span>',
    '#ajax' => array(
      'callback' => 'ajax_go_tool_funcat_example_id_callback',
      'wrapper'  => 'id-textarea',
      'method'   => 'replace',
      'effect'   => 'fade',
    ),
  );

  // Textfield for submitting a ID list for query
  $form['query']['ID'] = array(
    '#type' => 'textarea',
    '#title' => t('Enter gene IDs'),
    '#description'=>t('Enter gene IDs in the text area.'),
    '#prefix' => '<div id="id-textarea">',
    '#suffix' => '</div>',
  );

  // Upload a file as an alternative to enter a query ID
  $form['#attributes']['enctype'] = 'multipart/form-data';
  $form['query']['UPLOAD'] = array(
    '#title' => 'Or upload the file containing the list of gene IDs:  ',
    '#type' => 'managed_file',
    '#description' => t('The file should be a plain-text
  (.txt) file. Max size: %max_size. <strong>Don\'t forget to press the Upload button before
  attempting to submit your ID.</strong>',
      array(
        '%max_size' => round(file_upload_max_size() / 1024 / 1024,1) . 'MB'
      )
    ),
    '#upload_validators' => array(
      //'file_validate_extensions' => array('txt'),
      'file_validate_size' => array(file_upload_max_size()),
    ),
  );

  $form['choose_aspect'] = array(
    '#type' => 'radios',
    '#title' => t('Choose one of the three Ontologies:'),
    '#options' => array(
       'F' => t('Function'),
       'P' => t('Process'),
       'C' => t('Component'),
     ),
    '#default_value' => t('P'),
  );

  // Submit
  //.........................
  $form['submit'] = array(
    '#type' => 'submit',
    '#default_value' => ' Submit ',
  );

  $form['#prefix'] = '<div class="row"> <div class="col-md-8 col-md-offset-2">';
  $form['#suffix'] = '</div> </div>';

  return $form;
}

/**
 * Validate the user options submitted via the above form.
 *
 * @see go_tool_funcat_form().
 */
function go_tool_funcat_form_validate($form, &$form_state) {

  // Validate Query
  //----------------
  // @todo: We are currently not validating uploaded files are valid FASTA.
  // First check to see if we have an upload & if so then validate it.
  $file = file_load($form_state['values']['UPLOAD']);

  // If the $file is populated then this is a newly uploaded, temporary file.
  if (is_object($file)) {
    $form_state['qFlag'] = 'upQuery';
    $form_state['upQuery_path'] = drupal_realpath($file->uri);
  }
  // Otherwise there was no file uploaded.
  // Check if there was a query sequence entered in the texfield.
  elseif (!empty($form_state['input']['ID'])) {
    // Check to ensure that the query sequence entered is valid FASTA.
    // if (validate_fasta_sequence($type, $form_state['input']['ID'])){
    //  form_set_error('query', t('You need to provide a valid FASTA sequence '
    //  . 'for the query. It should contain a FASTA header/definition line '
    //  . 'followed by %molecule-type. For more information see the '
    //  . '<a href="@url" target="_blank">NCBI FASTA Specification</a>.',
    //    array(
    //      '%molecule-type' => $molecule_type,
    //      '@url' => 'http://www.ncbi.nlm.nih.gov/BLAST/blastcgihelp.shtml'
    //  )));
    //}
    //else {
      $form_state['qFlag'] = 'seqQuery';
    //}
  }
  // Otherwise they didn't enter a query!!
  else {
    form_set_error('query', t('No gene IDs given. Enter IDs in the box provided '
    . 'or upload a plain text file.'));
  }

  // Validate Dataset
  if (!empty($form_state['values']['SELECT_GO_DATASET'])) {
  }
  // Otherwise they didn't select a database!!
  else {
    form_set_error('DB', t('No dataset selected. Choose a dataset from the list.'));
  }

  // Validate ID list
  if (!empty($form_state['values']['ID']) && $form_state['values']['ID'] == 'unknown dataset type') {
    form_set_error('query', t('No gene IDs given.')); 
  } 
}


/**
 * Process the user options submitted.
 *
 * @see go_tool_funcat_form().
 */
function go_tool_funcat_form_submit($form, &$form_state) {

  $error = FALSE;

  // QUERY
  $gene_list = NULL;
  if (isset($form_state['qFlag'])) {
    if ($form_state['qFlag'] == 'seqQuery') {
      $seq_content = $form_state['values']['ID'];
      $gene_list = '/tmp/' . date('YMd_His') . '_GO_gene_list.txt';
      file_put_contents($gene_list, $seq_content);
    }
    elseif ($form_state['qFlag'] == 'upQuery') {
      $gene_list = $form_state['upQuery_path'];
    }
  }

  // GO annotation dataset
  $selected_db = $form_state['values']['SELECT_GO_DATASET'];

  // Determine the path to the GAF with extension.
  if (!is_readable($selected_db)) {
    $error = TRUE;
    // Reports error in admin>>reports>>Recent Log Messages
    tripal_report_error(
      'go_tool',
      TRIPAL_ERROR,
      "The GO dataset is unaccessible."
    );
    // report error in current page
    $msg = "The GO dataset '$selected_db' is unaccessible. ";
    $msg .= "Please contact the site administrator.";
    drupal_set_message($msg, 'error');
  }

  // OPTIONS
  $options = array(
     'a' => $form_state['values']['choose_aspect'],
  );

  // SUBMIT JOB TO TRIPAL
  //-------------------------
  if (!$error) {
    global $user;

    // set output file
    $output_dir = variable_get('file_public_path', conf_path() . '/files')
      . DIRECTORY_SEPARATOR . 'tripal' . DIRECTORY_SEPARATOR . 'tripal_goclassify';
    $output_file = $output_dir . DIRECTORY_SEPARATOR . date('YMd_His') . '.funcat';

    $funcat_program = $goenrich_program = DRUPAL_ROOT . DIRECTORY_SEPARATOR . drupal_get_path('module', 'go_tool') . DIRECTORY_SEPARATOR . 'go_funcat_tool.pl';

    $job_args = array(
      'program' => $funcat_program,
      'gene_list' => $gene_list,
      'go_annotation' => $selected_db,
      'output_file' => $output_file,
      'options' => $options
    );

    $job_id = tripal_add_job(
      t('GO gene classifcation for @go_annotation', array('@go_annotation' => $selected_db )),
      'tripal_go',
      'run_funcat_tripal_job',
      $job_args,
      $user->uid
    );

    //Encode the job_id
    $job_encode_id = go_tool_make_secret($job_id);
    drupal_goto("funcat/report/$job_encode_id");
  }
}

/**
 * AJAX: Replace the ID textarea with one containing an example.
 */
function ajax_go_tool_funcat_example_id_callback($form, $form_state) {
  $dataset = $form_state['values']['SELECT_GO_DATASET'];

  $db_type = 'unknown GAF type';
  $example_ids = 'unknown GAF type';

  if (isset($form['#db_type'][$dataset]) && isset($form['#db_expid'][$dataset]) ) {
    $db_type = $form['#db_type'][$dataset];
    $example_ids = $form['#db_expid'][$dataset];
    $form['gaf_type']['#value'] = $db_type;
  }

  if ($form_state['values']['example_id']) {
    $form['query']['ID']['#value'] = $example_ids;
  }
  else {
    $form['query']['ID']['#value'] = '';
  }

  return $form['query']['ID'];
}

