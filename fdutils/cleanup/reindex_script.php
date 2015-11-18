<?php
/**
 * 
 * Reindexes all the site
 * 
 * This file should be inside a second lever dir relative to Mage Root: MageRoot/Dir1/Dir2/var_cleanup_script.php
 *      (Or change the $mageRoot definition bellow)
 * 
 * How To: php reindex_script.php
 *  */

$mageRoot = realpath(dirname(__FILE__).'/../..').'/';

echo "Loading Mage Library.\n";
require_once $mageRoot.'app/Mage.php';

Mage::app();
echo "Creating & Configuring Mage Process.\n";
$processes = Mage::getSingleton('index/indexer')->getProcessesCollection();
$processes->walk('setMode', array(Mage_Index_Model_Process::MODE_REAL_TIME));
$processes->walk('save');

echo "Start Reindex Process.\n";
$processes->walk('reindexAll');
$processes->walk('reindexEverything');

echo "\nReindexing done\n\n";
