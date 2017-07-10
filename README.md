# docker-mysql-backup

This is a simple docker container which can be used to create rotating backups
of a MySQL database. It can be run either as a stand-alone container, or linked
to another container running MySQL.

Checkout the [example docker-compose.yml](example/docker-compose.yml) for an
exmaple of linking the backup container to a MySQL container.

This image is based off of
[dkruger/cron](https://hub.docker.com/r/dkruger/cron/) which provides a simple
cron implementation. The cron daemon is used to execute `logrotate` which will
rotate a number of backups, using `mysqldump` to create a new backup file at
the end of the rotation.

## Using the image

The image is configurable via environment variables for configuring the MySQL
server, and the backup settings.

* `DB_NAME`: The name of the database to backup
* `DB_HOST`: The MySQL host to connect to, defaults to "mysql"
* `DB_USER`: The username for authenticating with `DB_HOST`, defaults to "root"
* `DB_PASSWORD`: The password for `DB_USER`, defaults to "password"
* `ROTATE_COUNT`: The number of backup files to keep, defaults to 8
* `BACKUP_CRONTAB`: The crontab time entry, defaults to daily at midnight
* `MYSQLDUMP_OPTIONS`: Flags passed to `mysqldump`, defaults to
`--single-transaction`
* `ROTATE_UID`: The UID to use for creating the backup files, defaults to 0
* `ROTATE_GID`: The GID to use for creating the backup files, defaults to 0

The image defines a single volume: `/backup` which is used to store the backup
images.

Here is an example command for executing the container linked with another
container called `mydb` which is hosting the MySQL DB we want backed up:
```bash
docker run \
    --name mydb-backup \
    --link mydb:mysql \
    -e DB_NAME="somedb" \
    -e DB_HOST="mysql" \
    -e DB_USER="someuser" \
    -e DB_PASSWORD="securepassword" \
    dkruger/mysql-backup:latest
```

## About permissions

The container utilizes `logrotate` to make its backups. Recent versions of
`logrotate` have become more strict with permissions, requiring that the folder
not be world-writeable, or if it is be given a user/group to su as. Because of
this you may need to specify a UID and GID that will have permissions to write
to the backup directory. Note that these are the ID numbers, not the names.
