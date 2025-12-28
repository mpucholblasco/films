# Films

Have your films organized.

This app will help you to keep all your films organized.

## System configuration

* crontab -e

```crontab
*/5 * * * * cd /usr/share/films && /usr/bin/rake RAILS_ENV=production films:update_disk[/home/marcel/.aMule/Incoming] > /dev/null 2>&1
```

* logrotate

Generate file `/etc/logrotate.d/films` with content:

```
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

```ini
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

Allow user to mount `/media/usb`:
```bash
addgroup ntfsuser
chown root:ntfsuser $(which ntfs-3g)
chown root:ntfsuser /media/usb/
chmod g+w /media/usb
chmod 4750 $(which ntfs-3g)
usermod -aG ntfsuser www-data
usermod -aG disk www-data
```

Edit `/etc/fstab` and add:
```
/dev/sdb1	/media/usb	ntfs-3g	defaults,gid=1001,user,noauto,rw	0	0
```

## Developing

### In container
You need VS Code extension `Remote development`.

Then, use CMD+SHIFT+P and select `Dev Containers: Open Folder in Container...`.

After it, open a new terminal and execute:
```bash
bundle exec rails db:migrate
```

If you want to run the server in the container:
```bash
bundle exec rails s
```

You can access to the application via http://127.0.0.1:3000/.

# Pending
* Copy to external
* Update disks (needs to mount)
* Update internal disk
