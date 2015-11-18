<?php

/**
 * Deletes the following folders inside var/
 *      log/
 *      report/
 *      cache/
 * 
 * This file should be inside a second lever dir relative to Mage Root: MageRoot/Dir1/Dir2/var_cleanup_script.php
 *      (Or change the $mageRoot definition bellow)
 * 
 * How To: php var_cleanup_script.php
 *  */

$mageRoot = realpath(dirname(__FILE__).'/../..').'/';


clean_var_directory();

 
function clean_var_directory() {
    $dirs = array(
        'var/log/',
        'var/report/',
        'var/cache/',
    );
   
    foreach($dirs as $v => $k) {
        exec('rm -rf '.$mageRoot.$k);
    }
}
?>
