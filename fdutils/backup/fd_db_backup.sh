##############################################################################################################
#HOW TO
#
#sh ./fd_db_backup.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w}
#
#{magento_root_dir} -> The folder which has the folders app/, media/, var/, skin/.
#{s3_bucket_name}   -> The S3 Bucket Name that will be used for the backups. Something like domain.com-dbbackup is always a good choice.
#{hourly|daily_m|daily_w}  -> The type of backup file. 
#		If hourly, it will create a file called dbname_hourly_n.tar.gz. Where "n" is the current hour (24 hour format) (1 am is 1, not 01) 
#		If daily_m, it will create a file called dbname_daily_m_nn.tar.gz. Where "nn" is the day of the month
#		If daily_w, it will create a file called dbname_daily_m_nn.tar.gz. Where "nn" is the day of the week
##############################################################################################################

#check that we have mage and backup dirs in arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Wrong Usage: use it like this ./fd_db_backup.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w}"
	exit
fi

MAGENTO_PATH=$1
S3BUCKET=$2
TYPE=$3

DB_USER=$(sed -n 's|<username><\!\[CDATA\[\(.*\)\]\]></username>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_PASS=$(sed -n 's|<password><\!\[CDATA\[\(.*\)\]\]></password>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_NAME=$(sed -n 's|<dbname><\!\[CDATA\[\(.*\)\]\]></dbname>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_PREFIX=$(sed -n 's|<table_prefix><\!\[CDATA\[\(.*\)\]\]></table_prefix>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')

LOG=${MAGENTO_PATH}/var/log/imagecleanup.log
OUTPUT=$MAGENTO_PATH"/var/dbbutemp/"

if [ "hourly" == $TYPE ];  then
	echo "$TYPE Backup"
	FILENAME=$OUTPUT$DB_NAME"_"$TYPE"_"$(date +%-H) 
fi
if [ "daily_w" == $TYPE ]; then
	echo "$TYPE (week) Backup"
	FILENAME=$OUTPUT$DB_NAME"_"$TYPE"_"$(date +%-u)
fi
if [ "daily_m" == $TYPE ]; then
	echo "$TYPE (month) Backup"
	FILENAME=$OUTPUT$DB_NAME"_"$TYPE"_"$(date +%-d)
fi

#echo "DELETE S3 bucket: $S3BUCKET"
#s3cmd -f rb s3://$S3BUCKET

#Check that bucket exists, create if it doesn't
EXISTS=$(s3cmd info s3://$S3BUCKET)

if [ -z "$EXISTS" ]; then
	echo "Creating bucket $S3BUCKET"
	s3cmd mb s3://$S3BUCKET
else
	echo "Bucket $S3BUCKET found"
fi

echo "MAKE Temp Backup dir: $OUTPUT"
mkdir $OUTPUT

echo "Creating DB Dump"
mysqldump --force --opt --user=$DB_USER --password=$DB_PASS --databases $DB_NAME > $FILENAME.sql
echo "Compressing DB Dump"
tar -pczf $FILENAME.tar.gz -C $OUTPUT $(basename $FILENAME).sql


#Check if file exists, delete if it does
EXISTS=$(s3cmd info s3://$S3BUCKET/$(basename $FILENAME).tar.gz)

if [ -z "$EXISTS" ]; then
	echo "File "$(basename $FILENAME)" good to go"
else	
	echo "File "$(basename $FILENAME)" exists. Deleting..."
	s3cmd del s3://$S3BUCKET/$(basename $FILENAME).tar.gz
fi

#copy to s3
echo "COPY to S3 bucket: $S3BUCKET"
s3cmd put $FILENAME.tar.gz  s3://$S3BUCKET

echo "DELETE Temp Backup dir: $OUTPUT"
rm -rf $OUTPUT
