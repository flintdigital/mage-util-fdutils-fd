#!/bin/bash

##############################################################################################################
#HOW TO
#
#At shell run:
#sh ./fd_media_backup.sh {magento_root_dir} {backup_dest_dir} {s3_bucket_name}
#
#{magento_root_dir} -> The folder which has the folders app/, media/, var/, skin/.
#{backup_dest_dir}  -> The folder that will hold the backups. These backups will be removed. Folder needs to be writable
#{s3_bucket_name}   -> The S3 Bucket Name that will be used for the backups. Something like domain.com-mediabackup is always a good name.
#
#TODO: extra folders [media/extraFolder1,media/extraFolder2,...,n]
##############################################################################################################


#check that we have mage and backup dirs in arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Wrong Usage: use it like this ./fd_media_backup.sh {magento_root_dir} {backup_dest_dir} {s3_bucket_name}"
	exit
fi

#Make sure Mage dir given doesn't has final slash (standard to add it in the script)
MAGENTO_DIR=${1%/}

#Make sure Backup dir given doesn't has final slash (standard to add it in the script)
BACKUP_DIR=${2%/}

#check that magento directory is valid
if [ ! -d "$MAGENTO_DIR" -o ! -d $MAGENTO_DIR"/app/etc" -o ! -f $MAGENTO_DIR"/app/etc/local.xml" ]; then
	echo "The magento directory is not valid. It should be were your media/ and app/ folders are."
	exit
fi

#check that backup directory is writable
if [ ! -w $BACKUP_DIR ]; then
	echo "The backup folder is not writable."
	exit
fi

MEDIA_CAT_PROD_DIR=$MAGENTO_DIR"/media/catalog/product/"

BACKUP_DIR=$BACKUP_DIR/$(date +%-Y%-m%-d)/
S3BUCKET=$3;

if [ -z "$4" ]; then
	SUFIX=""
else
	SUFIX=$(date +%-u)"_"
fi

EXISTS=$(s3cmd info s3://$S3BUCKET)
echo $EXISTS;
if [ -z "$EXISTS" ]; then
	echo "Creating bucket $S3BUCKET"
	s3cmd mb s3://$S3BUCKET
else
	echo "Bucket $S3BUCKET found"
fi

echo "MAKE Temp Backup dir: $BACKUP_DIR"
mkdir $BACKUP_DIR
#created backup archives
echo "Saving product media"
for i in $MEDIA_CAT_PROD_DIR* ; do
  if [ -d "$i" ]; then
    if [[ "$i" != $MEDIA_CAT_PROD_DIR'cache' ]] && [[ "$i" != $MEDIA_CAT_PROD_DIR'-' ]] && [[ "$i" != $MEDIA_CAT_PROD_DIR'_' ]] ; then
    	FILENAME=$SUFIX$(basename "$i").tar.gz
    	echo $MEDIA_CAT_PROD_DIR$(basename "$i")"/ ==> $BACKUP_DIR$FILENAME"
	tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" catalog/product/$(basename "$i")
    fi
  fi
done

#lets do some one off backups
echo "Saving category media"
FILENAME=$SUFIX"category.tar.gz"
tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" catalog/category/

echo "Saving wysiwyg media"
FILENAME=$SUFIX"wysiwyg.tar.gz"
tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" wysiwyg/

for i in $BACKUP_DIR*.tar.gz ; do
	#check if file is bigger than 5GB (S3 Restriction). Split if it is
	BUSIZE=$(stat -c %s $i)
	if [ $BUSIZE -gt 5000000000 ]; then
		echo "Splitting file $i. Total size: $BUSIZE"
		split -b1000000000 $i $i-
		echo "Removing file $i"
		rm $i;
	fi
done


#copy to s3, forced to overwrite.
echo "COPY to S3 bucket: $S3BUCKET"
s3cmd -r -f put $BACKUP_DIR  s3://$S3BUCKET

echo "DELETE Temp Backup dir: $BACKUP_DIR"
rm -rf $BACKUP_DIR
