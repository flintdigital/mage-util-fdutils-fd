#!/bin/bash

##############################################################################################################
#HOW TO
#
#Make sure the script has execution permissions
#At shell run:
#sh ./fd_media_backup.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}
#
#{magento_root_dir} -> The folder which has the folders app/, media/, var/, skin/.
#{s3_bucket_name}   -> The S3 Bucket Name that will be used for the backups. Something like domain.com-mediabackup is always a good name.
#{hourly|daily_m|daily_w|single|monthly}  -> The type of backup file. 
#		If hourly, it will create a file called dbname_hourly_n.tar.gz. Where "n" is the current hour (24 hour format) (1 am is 1, not 01) 
#		If daily_m, it will create a file called dbname_daily_m_nn.tar.gz. Where "nn" is the day of the month
#		If daily_w, it will create a file called dbname_daily_w_n.tar.gz. Where "n" is the day of the week
#		If single, it will create a file called dbname_single.tar.gz
#		If monthly, it will create a file called dbname_monthly_nn.tar.gz. Where "nn" is the current month
#
##############################################################################################################


#check that we have mage and backup dirs in arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Wrong Usage: use it like this ./fd_media_backup.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}"
	exit
fi

#Make sure Mage dir given doesn't has final slash (standard to add it in the script)
MAGENTO_DIR=${1%/}

BACKUP_DIR=$MAGENTO_DIR"/var"

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

S3BUCKET=$2;
TYPE=$3;
BACKUP_DIR=$BACKUP_DIR/$TYPE"_"$(date +%-Y%-m%-d)/

if [ "hourly" == $TYPE ];  then
	echo "$TYPE Backup"
	SUFIX=$TYPE"_"$(date +%-H)"_"
elif [ "daily_w" == $TYPE ]; then
	echo "$TYPE (week) Backup"
	SUFIX=$TYPE"_"$(date +%-u)"_"
elif [ "daily_m" == $TYPE ]; then
	echo "$TYPE (month) Backup"
	SUFIX=$TYPE"_"$(date +%-d)"_"
elif [ "single" == $TYPE ]; then
	echo "$TYPE Backup"
	SUFIX=$TYPE"_"
elif [ "monthly" == $TYPE ]; then
	echo "$TYPE Backup"
	SUFIX=$TYPE"_"$(date +%-m)"_"
else
	echo "$TYPE backup type not supported. Valid Options: hourly, daily_m, daily_w, single, monthly."
	exit
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
#save product images
echo "Saving product media"
for i in $MEDIA_CAT_PROD_DIR* ; do
  if [ -d "$i" ]; then
    if [[ "$i" != $MEDIA_CAT_PROD_DIR'cache' ]] && [[ "$i" != $MEDIA_CAT_PROD_DIR'-' ]] && [[ "$i" != $MEDIA_CAT_PROD_DIR'_' ]] ; then
    	FILENAME=$SUFIX"catalog_product_"$(basename "$i").tar.gz
    	echo $MEDIA_CAT_PROD_DIR$(basename "$i")"/ ==> $BACKUP_DIR$FILENAME"
	tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" catalog/product/$(basename "$i")
    fi
  fi
done

MEDIA_CAT_DIR=$MAGENTO_DIR"/media/catalog/"
#Save all other media/catalog/* folders (except cache and product)
echo "Saving media/catalog images"
for i in $MEDIA_CAT_DIR* ; do
  if [ -d "$i" ]; then
    if [[ "$i" != $MEDIA_CAT_DIR'cache' ]] && [[ "$i" != $MEDIA_CAT_DIR'product' ]] ; then
    	FILENAME=$SUFIX"catalog_"$(basename "$i").tar.gz
    	echo $MEDIA_CAT_DIR$(basename "$i")"/ ==> $BACKUP_DIR$FILENAME"
	tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" catalog/$(basename "$i")
    fi
  fi
done

MEDIA_DIR=$MAGENTO_DIR"/media/"
#Save all other media/ folders (except cache)
echo "Saving all other media images"
for i in $MEDIA_DIR* ; do
  if [ -d "$i" ]; then
    if [[ "$i" != $MEDIA_DIR'cache' ]] && [[ "$i" != $MEDIA_DIR'catalog' ]] ; then
    	FILENAME=$SUFIX$(basename "$i").tar.gz
    	echo $MEDIA_DIR$(basename "$i")"/ ==> $BACKUP_DIR$FILENAME"
	tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" $(basename "$i")
    fi
  fi
done

#echo "Saving category media"
#FILENAME=$SUFIX"category.tar.gz"
#tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" catalog/category/

#echo "Saving wysiwyg media"
#FILENAME=$SUFIX"wysiwyg.tar.gz"
#tar -pczf $BACKUP_DIR$FILENAME -C "$MAGENTO_DIR/media/" wysiwyg/

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
