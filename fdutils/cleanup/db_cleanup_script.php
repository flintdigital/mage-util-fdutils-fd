<?php

/**
 * Deletes DB tables used for logging purposes. These can add GBs to a DB size
 *  
 * This file should be inside a second lever dir relative to Mage Root: MageRoot/Dir1/Dir2/var_cleanup_script.php
 *      (Or change the $mageRoot definition bellow)
 * 
 * How To: php db_cleanup_script.php
 *  */


$mageRoot = realpath(dirname(__FILE__).'/../..').'/';

$xml = simplexml_load_file($mageRoot.'app/etc/local.xml', NULL, LIBXML_NOCDATA);
 
$db['host'] = $xml->global->resources->default_setup->connection->host;
$db['name'] = $xml->global->resources->default_setup->connection->dbname;
$db['user'] = $xml->global->resources->default_setup->connection->username;
$db['pass'] = $xml->global->resources->default_setup->connection->password;
$db['pref'] = $xml->global->resources->db->table_prefix;

clean_log_tables();


function clean_log_tables() {
    global $db;
   
    $tables = array(
     'dataflow_batch_export',
     'dataflow_batch_import',
     'log_customer',
     'log_quote',
     'log_summary',
     'log_summary_type',
     'log_url',
     'log_url_info',
     'log_visitor',
     'log_visitor_info',
     'log_visitor_online',
     'index_event',
     'report_event',
     'report_viewed_product_index',
     'report_compared_product_index',
     'catalog_compare_item',
     'catalogindex_aggregation',
     'catalogindex_aggregation_tag',
     'catalogindex_aggregation_to_tag'
    );
    
    echo "Connecting to DB\n";
   
    mysql_connect($db['host'], $db['user'], $db['pass']) or die(mysql_error());
    mysql_select_db($db['name']) or die(mysql_error());
   
    foreach($tables as $v => $k) {
        echo "Truncating $k\n";
        mysql_query('TRUNCATE `'.$db['pref'].$k.'`') or die(mysql_error());
    }
    
    echo "Finished!\n\n";
}
 
?>
