#!/bin/bash

###################################
##    Nextcloud backup script    ##
###################################

# Logging should be enabled by adding a redirection to /var/logs/nextcloud-backup.sh when calling the script.

NEXTCLOUD_APP_NAME="Cloud"
NEXTCLOUD_DB_NAME="nextcloud"
NEXTCLOUD_SOURCE_PATH="/var/www/nextcloud"
NEXTCLOUD_DATA_PATH="/var/www/nextcloud_data"
NEXTCLOUD_BACKUP_PATH="/tmp/nextcloud_backup"
NEXTCLOUD_BACKUP_DROP_OFF="/home/service_backup"

APACHE_CONF_PATH="/etc/apache2/sites-available"
PHP_INI_FILE="/etc/php/7.3/apache2/php.ini"

echo -e "\n$(date --rfc-3339="seconds")\tStarting backup script for \"$NEXTCLOUD_APP_NAME\"."


if $(test -d $NEXTCLOUD_BACKUP_PATH)
then
	echo -e "$(date --rfc-3339="seconds")\tTemporary backup directory already exists. Deleting its contents to make room for the new files."
	rm -r $NEXTCLOUD_BACKUP_PATH/*
else
	echo -e "$(date --rfc-3339="seconds")\tTemporary backup directory NOT found at $NEXTCLOUD_BACKUP_PATH - Creating it."
	mkdir $NEXTCLOUD_BACKUP_PATH
fi

echo -e "$(date --rfc-3339="seconds")\tEnabling maintenance mode now."
sudo -u www-data php $NEXTCLOUD_SOURCE_PATH/occ maintenance:mode --on

echo -e "$(date --rfc-3339="seconds")\tCreating manifest file with script settings."
echo -e "Archive creation date: $(date --rfc-3339="seconds")" >> $NEXTCLOUD_BACKUP_PATH/README.md
echo -e "\nSettings:" >> $NEXTCLOUD_BACKUP_PATH/README.md
echo -e " - NEXTCLOUD_APP_NAME: $NEXTCLOUD_APP_NAME" >> $NEXTCLOUD_BACKUP_PATH/README.md
echo -e " - NEXTCLOUD_SOURCE_PATH: $NEXTCLOUD_SOURCE_PATH" >> $NEXTCLOUD_BACKUP_PATH/README.md
echo -e " - NEXTCLOUD_DATA_PATH: $NEXTCLOUD_DATA_PATH" >> $NEXTCLOUD_BACKUP_PATH/README.md
echo -e " - APACHE_CONF_PATH: $APACHE_CONF_PATH" >> $NEXTCLOUD_BACKUP_PATH/README.md
echo -e " - PHP_INI_FILE: $PHP_INI_FILE" >> $NEXTCLOUD_BACKUP_PATH/README.md

echo -e "$(date --rfc-3339="seconds")\tDumping $NEXTCLOUD_DB_NAME database."
sudo mysqldump --opt $NEXTCLOUD_DB_NAME > $NEXTCLOUD_BACKUP_PATH/$NEXTCLOUD_DB_NAME-db-dump.sql

echo -e "$(date --rfc-3339="seconds")\tCopying $NEXTCLOUD_DATA_PATH"
cp -r $NEXTCLOUD_DATA_PATH $NEXTCLOUD_BACKUP_PATH/nextcloud_data

echo -e "$(date --rfc-3339="seconds")\tCopying $NEXTCLOUD_SOURCE_PATH"
cp -r $NEXTCLOUD_SOURCE_PATH $NEXTCLOUD_BACKUP_PATH/nextcloud_source

echo -e "$(date --rfc-3339="seconds")\tCopying $APACHE_CONF_PATH"
cp -r $APACHE_CONF_PATH $NEXTCLOUD_BACKUP_PATH/apache_conf

echo -e "$(date --rfc-3339="seconds")\tCopying $PHP_INI_FILE"
cp -r $PHP_INI_FILE $NEXTCLOUD_BACKUP_PATH/php.ini

echo -e "$(date --rfc-3339="seconds")\tArchiving and compressing files."
cd $NEXTCLOUD_BACKUP_PATH
tar -cz -C $NEXTCLOUD_BACKUP_PATH -f NEXTCLOUD_BCKP-$(date --rfc-3339='date').tar.gz $NEXTCLOUD_BACKUP_PATH

echo -e "$(date --rfc-3339="seconds")\tNew archive's hash:"
sha256sum NEXTCLOUD_BCKP-$(date --rfc-3339="date").tar.gz

echo -e "$(date --rfc-3339="seconds")\tMoving the backup file to desired folder for pickup."
mv $(echo $NEXTCLOUD_BACKUP_PATH)/NEXTCLOUD_BCKP-$(date --rfc-3339='date').tar.gz $(echo $NEXTCLOUD_BACKUP_DROP_OFF)/

echo -e "$(date --rfc-3339="seconds")\tCleaning up $NEXTCLOUD_BACKUP_PATH"
rm -r $NEXTCLOUD_BACKUP_PATH/*

echo -e "$(date --rfc-3339="seconds")\tDisabling maintenance mode for $NEXTCLOUD_APP_NAME"
sudo -u www-data php $NEXTCLOUD_SOURCE_PATH/occ maintenance:mode --off

echo -e "$(date --rfc-3339="seconds")\tEnd of script."
