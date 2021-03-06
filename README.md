# Films

Have your films organized.

This app will help you to keep all your films organized.

## System configuration

* crontab -e

```bash
*/5 * * * * cd /usr/share/films && /usr/bin/rake RAILS_ENV=production films:update_disk[/home/marcel/.aMule/Incoming] > /dev/null 2>&1
```

* logrotate

Generate file `/etc/logrotate.d/films` with content:

```bash
/usr/share/films/log/*.log {
  daily
  missingok
  rotate 7
  compress
  delaycompress
  notifempty
  copytruncate
}
```

Avoid `fsck` interactivity on boot
Edit file `/etc/default/rcS` and set `FSCKFIX=yes`

Service for delayed jobs:

1. Edit file `/etc/systemd/system/films_delayed_job.service` and set this
   content:

```bash
[Unit]
Description=Films delayed jobs
Requires=mysql.service
After=mysql.service

[Service]
Environment=RAILS_ENV=production
Type=forking
ExecStart=/usr/share/films/bin/delayed_job start
ExecStop=/usr/share/films/bin/delayed_job stop
Restart=on-failure
PIDFile=/usr/share/films/tmp/pids/delayed_job.pid
```

Allow rails app to move files from films:

```bash
sudo setfacl --default -m u::rwx,u:www-data:rwx /home/marcel/myfolder/
```

## Copying files to external

To copy files to an external USB, you need to have installed usbmount via:
`sudo apt-get install usbmount`

To configure usbmount, edit file `/etc/usbmount/usbmount.conf` and set the following variable value:
`MOUNTOPTIONS="async,noexec,nodev,noatime,nodiratime,user,umask=0000"`
`FS_MOUNTOPTIONS="-fstype=vfat,gid=www-data,dmask=0002,fmask=0113,utf8"`

Ensure to remove `sync` from usbmount option.

## Generating tests

See [https://www.webascender.com/Blog/ID/566/Testing-Rails-4-Apps-With-RSpec-3-Part-I#.WGePRrYrK9s](https://www.webascender.com/Blog/ID/566/Testing-Rails-4-Apps-With-RSpec-3-Part-I#.WGePRrYrK9s).

To generate rspecs: `bin/rails generate rspec:model Disks`

To execute tests: `bin/rspec`
