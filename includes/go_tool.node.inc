<?php

/**
 * @file
 * Contains all functions for creating the gaf (GO Annotation File) node type
 */

/**
 * Implements hook_node_info().
 */
function go_tool_node_info() {
  return array(
    'gaf' => array(
      'name' => t('GO Database'),
      'base' => 'gaf',
      'description' => t('Add a GO Annotation File (GAF) for GO enrichment analysis.'),
    ),
  );
}

/**
 * Implements hook_node_access().
 */
function gaf_node_access($node, $op, $account) {
  $node_type = $node;
  if (is_object($node)) {
    $node_type = $node->type;
  }

  if($node_type == 'gaf') {
    if ($op == 'create') {
      if (!user_access('create GO Annotation File', $account)) {
        return NODE_ACCESS_DENY;
      }
      return NODE_ACCESS_ALLOW;
    }
    if ($op == 'update') {
      if (!user_access('edit GO Annotation File', $account)) {
        return NODE_ACCESS_DENY;
      }
    }
    if ($op == 'delete') {
      if (!user_access('delete GO Annotation File', $account)) {
        return NODE_ACCESS_DENY;
      }
    }
    if ($op == 'view') {
      if (!user_access('access GO Annotation File', $account)) {
        return NODE_ACCESS_DENY;
      }
    }

    return NODE_ACCESS_IGNORE;
  }
}

/**
 * Form constructor for the gaf node
 *
 * @see gaf_insert()
 * @see gaf_update()
 * @see gaf_delete()
 * @see gaf_load()
 */
function gaf_form($node, &$form_state) {
  $form = array();

  $form['#validate'] = array('gaf_form_validate');
  
  $form['core'] = array(
    '#type' => 'fieldset',
    '#title' => 'General'
  );

  $form['core']['db_name']= array(
    '#type' => 'textfield',
    '#title' => t('Human-readable Name for GO Annotation File'),
    '#required' => TRUE,
    '#default_value' => isset($node->db_name) ? $node->db_name : '',
    '#description' => t('For example: watermelon genome (97103)'),
  );

  $form['core']['db_path']= array(
    '#type' => 'textfield',
    '#title' => t('File Prefix including Full Path'),
    '#description' => t('The full path to your GAF. For example, /home/web/GO/watermelon_97103_1_assoc'),
    '#required' => TRUE,
    '#default_value' => isset($node->db_path) ? $node->db_path : '',
  );

  $form['core']['db_dbtype'] = array(
    '#type' => 'radios',
    '#title' => t('Type of the GAF'),
    '#description' => t('The feature used to generate GAF. For example, gene'),
    '#options' => array(
      'gene' => t('gene'),
      'transcribed_cluster' => t('unigene'),
    ),
    '#required' => TRUE,
    '#default_value' => isset($node->db_dbtype) ? $node->db_dbtype : 'gene',
  );

  $form['core']['db_example_id'] = array(
    '#type' => 'textarea',
    '#title' => t('Example of IDs One, ID for each line '),
    '#required' => TRUE,
    '#default_value' => isset($node->db_example_id) ? $node->db_example_id : '',
    '#description' => t('The IDs will be used as example for correspond GAF.'),
    '#cols' => 30,
    '#rows' => 10,
    '#maxlength' => 1000,
  );


  return $form;
}

function gaf_form_validate($form, $form_state) {

}

/**
 * Implements hook_insert().
 */
function gaf_insert($node) {
  
  // Actually insert the record.
  db_insert('gaf')->fields(array(
    'nid'                 => $node->nid,
    'name'                => $node->db_name,
    'path'                => $node->db_path,
    'dbtype'              => $node->db_dbtype,
    'idexample'           => $node->db_example_id,
  ))->execute();
}

/**
 * Implements hook_node_insert().
 * This function acts on ALL NODES
 */
function go_tool_node_insert($node) {
  if ($node->type == 'gaf') {
    $node->title = $node->db_name;
  }
}

/**
 * Implements hook_update().
 * modify gaf in database level
 */
function gaf_update($node) {
  // Update the record.
  db_update('gaf')->fields(array(
    'name'                => $node->db_name,
    'path'                => $node->db_path,
    'dbtype'              => $node->db_dbtype,
    'idexample'           => $node->db_example_id,
  ))->condition('nid', $node->nid)->execute();
}

/**
 * Implements hook_node_update().
 * This function acts on ALL NODES
 * for go_tool_node
 */
function go_tool_node_update($node) {
  if ($node->type == 'gaf')  {
    $node->title = $node->db_name;
  }
}

/**
 * Implements hook_delete(). 
 * modify gaf in database level 
 */
function gaf_delete($node) {
  db_delete('gaf')->condition('nid',$node->nid)->execute();
}

/**
 * Implements hook_load().
 * modify gaf in database level
 */
function gaf_load($nodes) {

  $sql = "
    SELECT nid, name, path, dbtype, idexample
    FROM {gaf} 
    WHERE nid IN (:nids)";
  $result = db_query($sql, array(':nids' => array_keys($nodes)));

  foreach ($result as $record) {
    $nodes[$record->nid]->db_name = $record->name;
    $nodes[$record->nid]->db_path = $record->path;
    $nodes[$record->nid]->title = $record->name;
    $nodes[$record->nid]->db_dbtype = $record->dbtype;
    $nodes[$record->nid]->db_example_id = $record->idexample;
  }
}

