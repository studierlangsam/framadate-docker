#! /bin/sh
set -e

cp -Rp /opt/www/framadate /var/www

configerror=false

requireenv() {
  varname="$1"
  if eval "\${$varname+false}"; then
    echo "Please provide the required environment variable '$varname'"!
    configerror=true
  fi
}

requireenvposint() {
  varname="$1"
  varvalue="$(eval "echo \$$varname")"
  if ! echo "$varvalue" | egrep -q '^[1-9][0-9]*$'; then
    echo "The environment variable '$varname' must be set to a positive integer (is: '$varvalue')!"
    configerror=true
  fi
}

requireenvbool() {
  varname="$1"
  varvalue="$(eval "echo \$$varname")"
  if [ "$varvalue" != false ] && [ "$varvalue" != true ]; then
    echo "The environment variable '$varname' must be set to true or false (is: '$varvalue')!"
    configerror=true
  fi
}

defaultenv() {
  varname="$1"
  vardefault="$2"
  if eval "\${$varname+false}"; then
    echo "The environment variable '$varname' was not provided, setting it to '$vardefault'."
    eval "export $varname="'"'"$vardefault"'"'
  fi
}

defaultenv APPLICATION_NAME "Framadate"
requireenv APPLICATION_URL
requireenv ADMIN_EMAIL
requireenv EMAIL_FROM_ADDRESS
requireenv MYSQL_HOST
defaultenv MYSQL_DATABASE "framadate"
defaultenv MYSQL_PORT "3306"
requireenvposint MYSQL_PORT
requireenv MYSQL_USER
requireenv MYSQL_PASSWORD
defaultenv MYSQL_TABLE_PREFIX "fd_"
defaultenv MYSQL_MIGRATION_TABLE "fd_migration"
defaultenv DEFAULT_LANGUAGE "en"
defaultenv PURGE_DELAY_DAYS 60
requireenvposint PURGE_DELAY_DAYS
defaultenv MAX_SLOTS_PER_POLL 366
requireenvposint MAX_SLOTS_PER_POLL
defaultenv USE_SMTP "true"
requireenvbool USE_SMTP
defaultenv SMTP_HOST localhost
defaultenv SMTP_AUTH "false"
requireenvbool SMTP_AUTH
if [ "$SMTP_AUTH" = true ]; then
  requireenv SMTP_AUTH_USER
  requireenv SMTP_AUTH_PASSWORD
fi
defaultenv SMTP_SECURE ""
if [ "$SMTP_SECURE" = "" ]; then
  defaultenv SMTP_PORT "25"
elif [ "$SMTP_SECURE" = "tls" ] || [ "$SMTP_SECURE" = "ssl" ]; then
  defaultenv SMTP_PORT "587"
fi
requireenvposint SMTP_PORT
defaultenv SHOW_HOW_TO "true"
requireenvbool SHOW_HOW_TO
defaultenv SHOW_SOFTWARE_DESCRIPTION "true"
requireenvbool SHOW_SOFTWARE_DESCRIPTION
defaultenv SHOW_SOFTWARE_LINK "true"
requireenvbool SHOW_SOFTWARE_LINK
defaultenv DEFAULT_POLL_DURATION_DAYS 180
requireenvposint DEFAULT_POLL_DURATION_DAYS

if [ "$configerror" = true ]; then
  exit 1
fi

envsubst '$APPLICATION_NAME $APPLICATION_URL $ADMIN_EMAIL $EMAIL_FROM_ADDRESS $MYSQL_HOST $MYSQL_DATABASE $MYSQL_PORT $MYSQL_USER $MYSQL_PASSWORD $MYSQL_TABLE_PREFIX $MYSQL_MIGRATION_TABLE $DEFAULT_LANGUAGE $PURGE_DELAY_DAYS $MAX_SLOTS_PER_POLL $USE_SMTP $SMTP_HOST $SMTP_AUTH $SMTP_AUTH_USER $SMTP_AUTH_PASSWORD $SMTP_SECURE $SMTP_PORT $SHOW_HOW_TO $SHOW_SOFTWARE_DESCRIPTION $SHOW_SOFTWARE_LINK $DEFAULT_POLL_DURATION_DAYS' < /opt/www/framadate/app/inc/config.php > /var/www/framadate/app/inc/config.php
touch /var/www/framadate/log
chown www-data /var/www/framadate/log
chown -R www-data /var/www/framadate/tpl_c
exec docker-php-entrypoint "$@"
