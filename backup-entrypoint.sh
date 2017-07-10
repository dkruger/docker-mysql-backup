#!/bin/sh

set -e

if [ -z "${DB_HOST}" -a -z "${MYSQL_PORT_3306_TCP}" ]; then
    echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
    echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
    exit 1
fi

# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${DB_USER:=root}
if [ "$DB_USER" = 'root' ]; then
    : ${DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi

: ${DB_HOST:=${MYSQL_PORT_3306_TCP#tcp://}}

# Create the logrotate definition
cat << EOF > /etc/logrotate.d/db-backup
/backup/${DB_NAME}.sql.gz {
rotate ${ROTATE_COUNT}
missingok
size 0
nocompress
create 640 root root
postrotate
mysqldump \
    -h "${DB_HOST}" \
    -u ${DB_USER} \
    -p"${DB_PASSWORD}" \
    ${MYSQLDUMP_OPTIONS} \
    "${DB_NAME}" \
    | gzip > "/backup/${DB_NAME}.sql.gz"
endscript
}
EOF

# Initialize a backup so logrotate will be happy
touch "/backup/${DB_NAME}.sql.gz"

# Setup our crontab entry
export CRONTAB_ENTRY="${BACKUP_CRONTAB} /usr/sbin/logrotate /etc/logrotate.d/db-backup"
