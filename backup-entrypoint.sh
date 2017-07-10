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

# Logrotate needs a valid user and group to su as
if ! getent group "${ROTATE_GID}" &>/dev/null; then
    addgroup -g "${ROTATE_GID}" "logrotate"
fi
ROTATE_GROUP="$(getent group "${ROTATE_GID}" | cut -d: -f1)"

if ! getent passwd "${ROTATE_UID}" &>/dev/null; then
    adduser -u "${ROTATE_UID}" -H "logrotate" "${ROTATE_GROUP}"
fi
ROTATE_USER="$(getent passwd "${ROTATE_UID}" | cut -d: -f1)"

if ! getent group "${ROTATE_GROUP}" | grep "${ROTATE_USER}" &>/dev/null; then
    addgroup "${ROTATE_USER}" "${ROTATE_GROUP}"
fi

# Create the logrotate definition
cat << EOF > /etc/logrotate.d/db-backup
/backup/${DB_NAME}.sql.gz {
su ${ROTATE_USER} ${ROTATE_GROUP}
rotate ${ROTATE_COUNT}
missingok
size 0
nocompress
create 644 ${ROTATE_USER} ${ROTATE_GROUP}
postrotate
sudo -u "${ROTATE_USER}" -g "${ROTATE_GROUP}" \
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
sudo -u "${ROTATE_USER}" -g "${ROTATE_GROUP}" touch "/backup/${DB_NAME}.sql.gz"

# Setup our crontab entry
export CRONTAB_ENTRY="${BACKUP_CRONTAB} /usr/sbin/logrotate /etc/logrotate.d/db-backup"
