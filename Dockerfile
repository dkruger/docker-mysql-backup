FROM dkruger/cron:latest

ENV \
    DB_HOST="mysql" \
    DB_USER="root" \
    DB_PASSWORD="password" \
    DB_NAME="mydb" \
    ROTATE_COUNT="8" \
    BACKUP_CRONTAB="0 0 * * 0" \
    MYSQLDUMP_OPTIONS="--single-transaction"

RUN set -x; \
    apk add --no-cache --update logrotate mariadb-client \
    && rm -rf /tmp/* \
    && rm -rf /var/cache/apk/*

VOLUME ["/backup"]
WORKDIR /backup

COPY backup-entrypoint.sh /entrypoint.d/mysql-backup.sh
