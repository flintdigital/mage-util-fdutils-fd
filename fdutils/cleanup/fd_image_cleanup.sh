#!/bin/bash

########
#HOW TO
#
#	At shell run:
#	$ ./fd_image_cleanup.sh {relative_path_to_mage_root_from_this_file} [cleanup]
#	First param is the relative path to mage root, from this script's file
#	Second param is to actually make the cleanup, if ommitted it will run a test and won't delete anything.
#
#DON'T USE IT WITH sh under debian/ubuntu: sh fd_image_clanup.sh won't work because of some incompatibility stuff between shells. 
#	More info here -> http://ubuntuforums.org/archive/index.php/t-499045.html
#
########

#Get script directory
MAGENTO_PATH=$(dirname $0)

#Get Directory Argument from CLI
if [ ! -z "$1" ] && [ ! $1 == 'cleanup' ]; then
    MAGENTO_PATH="$MAGENTO_PATH/$1"
    #Strip Last slash (if any) from the Magento Path
    MAGENTO_PATH=${1%/}
fi

#Check that the directory exists
if [ ! -d "$MAGENTO_PATH" ]; then
    echo "The directory doesn't exists."; exit
fi

#Check that this is a Magento Root directory: where we have the app/ media/ lib/ var/ folders
if [ ! -d $MAGENTO_PATH"/app/etc" ]; then
    echo "The directory is not a Magento Path."; exit
fi

#Check that the local.xml file exists, at this point that probably means Magento is not installed.
if [ ! -f $MAGENTO_PATH"/app/etc/local.xml" ]; then
    echo "Looks like Magento hasn't been installed yet."; exit
fi
#Define the Log File
LOG=${MAGENTO_PATH}/var/log/imagecleanup.log

#Get the DB Credentials from the local.xml file
DB_USER=$(sed -n 's|<username><\!\[CDATA\[\(.*\)\]\]></username>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_PASS=$(sed -n 's|<password><\!\[CDATA\[\(.*\)\]\]></password>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_NAME=$(sed -n 's|<dbname><\!\[CDATA\[\(.*\)\]\]></dbname>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')
DB_PREFIX=$(sed -n 's|<table_prefix><\!\[CDATA\[\(.*\)\]\]></table_prefix>|\1|p' ${MAGENTO_PATH}/app/etc/local.xml | tr -d ' ')

#Function that connects to the DB and runs a query to see if a given image is currently assigned to a product
#Uses 1 param: the file path and name relative to
function search_db() {
	COUNT=$(mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} --execute="SELECT count(*) FROM ${DB_PREFIX}catalog_product_entity_media_gallery WHERE value = \"$1\"")
	echo $(echo ${COUNT} | cut -d" " -f2)
}

echo "Starting image cleanup " $(date) | tee -a ${LOG}

#Get the Root Image Path for Magento Products
IMG_PATH=${MAGENTO_PATH}/media/catalog/product/

#The find instruction Gets all .jpg files in the Root Image Path that are not in any cache folder, and are don't have google in its name. 
#The for ... in goes through each Image
for IMG in $(find ${IMG_PATH} -name '*.jpg' ! -path '*cache*' ! -path '*placeholder*' ! -name 'google*'); do

	#Gets the full path of the Image
	IMAGE=/${IMG:${#IMG_PATH}}

	#Check to see if the image is not assigned to a product in the DB, removes it if not.
	if [ $(search_db ${IMAGE/'${MAGENTO_PATH}/media/catalog/product'/}) != 1 ]; then
		IMG=${IMG##*/}
		for IMAGE_FILE in $(find ${MAGENTO_PATH}/media/catalog/product/ -name "${IMG}"); do
			echo "Found unused image ${IMAGE_FILE}"
			if [ "$1" ] && [ $1 == 'cleanup' ]; then
				echo "Removing unused image ${IMAGE_FILE}" | tee -a ${LOG}
				rm "${IMAGE_FILE}"
			elif [ "$2" ] && [ $2 == 'cleanup' ]; then
				echo "Removing unused image ${IMAGE_FILE}" | tee -a ${LOG}
				rm "${IMAGE_FILE}"
			fi
		done
	else 
		echo "Not touching " ${IMG}
	fi
done
echo "Finished image cleanup " $(date) | tee -a ${LOG}

