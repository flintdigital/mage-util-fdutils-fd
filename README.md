# Flint Digital Utils for Magento

###Utility scripts for Magento.

* DB Backup script
* Media Folder Backup script
* Image Cleanup script (removes unused images)
* var/ folder cleanup: log/ report/ cache/
* DB log tables cleanup
* Site Reindex

Each script has a readme file with instructions on how to use it.

###Modgit Install
`modgit add mage-util-fdutils-fd git@github.com:flintdigital/mage-util-fdutils-fd.git`

###DB Backup script
`sh fd_db_backup.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}`

[More in Script's Readme File](https://github.com/flintdigital/mage-util-fdutils-fd/blob/master/fdutils/backup/fd_db_backup.readme "fd_db_backup.sh Readme File")

###Media Folder Backup script
`sh fd_media_backup.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}`

[More in Script's Readme File](https://github.com/flintdigital/mage-util-fdutils-fd/blob/master/fdutils/backup/fd_media_backup.readme "fd_media_backup.sh Readme File")

###Image Cleanup script (removes unused images)
`sh fd_image_cleanup.sh {magento_root_dir} [cleanup]`

[More in Script's Readme File](https://github.com/flintdigital/mage-util-fdutils-fd/blob/master/fdutils/cleanup/fd_image_cleanup.readme "fd_image_cleanup.sh Readme File")

###var/ folder cleanup: log/ report/ cache/
`php var_cleanup_script.php`

###DB log tables cleanup
`php db_cleanup_script.php`

###Site Reindex
`php reindex_script.php`
