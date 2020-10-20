# openITCOCKPIT in Docker

**Do not use this in production!** _#unstable_

It's a project to test whether openITCOCKPIT works as a basically default installation in a docker container.

Even [openITCOCKPIT in LXC](https://blog.binsky.org/blog/2019-12-06-Install-openITCOCKPIT-in-LXC/) is more stable than that.

## Setup

The container should get an automatically bridged ip address from the default 172.17.0.0/24 docker bridge.
If you want to specify a custom ip, add `--ip 172.17.0.3 \` as penultimate line to the setup command.

```
docker run -d --name oitc \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --mount type=bind,source="$(pwd)"/installer.sh,target=/installer.sh \
    --security-opt seccomp=unconfined \
    --privileged \
    fauust/docker-systemd:debian-10
docker exec -it oitc /installer.sh
```

Run `nmap -sn 172.17.0.0/24` to get the assigned ip addresses.

Login at e.g. `http://172.17.0.3` and register instance with the current community license key: `e5aef99e-817b-0ff5-3f0e-140c1f342792`


## Handling

### Command line login
`docker exec -it oitc /bin/bash`


### Backups

Use the frontend backup and restore functionality at https://172.17.0.3/#!/backups/index

Download a backup file from your old installation, copy it into the container and start a restore.
`docker cp openitcockpit_dump_2020-08-18_12-05-00.sql oitc:/opt/openitc/nagios/backup/`

After that logout and login with you user from the restored instance.

You may have to go to 'Manage User Roles', edit every role and click 'Update user role'.


### Updates

#### openITCOCKPIT Updates

To update openITCOCKPIT, log in to the container (`docker exec -it oitc /bin/bash`) and run `apt-get update && apt-get upgrade`.

After the update, manually check the files that are changed in the troubleshooting section below.

Stop and restart the container to make sure the update was successful and all services are working.

#### Container updates
We don't save configs or backups in a host volume, due to missing migration scripts between configuration versions.

This feature may be added in the future. However, it is currently of no relevance to me.


### Add port mapping to the existing container

In our default installation you don't need this.
Please use a reverse proxy (nginx) instead!

This method can take a while with an installed openITCOCKPIT. There are some GBs to backup to the new image.

Use this example to bind 0.0.0.0:8081 to the docker internal port 443.
```
docker stop oitc
docker commit oitc oitc2
docker rm oitc
docker run -d --name oitc \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p 8081:443
    --mount type=bind,source="$(pwd)"/installer.sh,target=/installer.sh \
    --security-opt seccomp=unconfined \
    --privileged \
    oitc2
```


## Troubleshooting

### php-fpm not starting

The currently used php fpm version of openITCOCKPIT is php7.3-fpm.

The socket path is defined at `/etc/php/7.3/fpm/pool.d/oitc.conf` and points to `/run/php/php-fpm-oitc.sock`.

Make sure the socket folder exists in the docker container: `mkdir -p /run/php`.

If php was not running, the required docker containers are also stopped.

Try to restart the container, after the php issue is fixed.

### Fix problems with the gearmand and docker
These commands were executed during the custom openITCOCKPIT installation.

Due to the openITCOCKPIT config generator, the customizations will be overwritten.
So if there were still problems, execute these commands again.

```
systemctl stop openitcockpit-graphing gearman-job-server
sed -e '/ExecStartPre/ s/^#*/#/' -i /lib/systemd/system/openitcockpit-graphing.service
sed -i "/image:\ openitcockpit\/carbon-c-relay:latest/c\\ \ \ \ image:\ mist\/carbon-c-relay" /opt/openitc/docker/container/graphing/docker-compose.yml
sed -i ':a;N;$!ba;s/\/opt\/openitc\/etc\/carbon:\/etc\/carbon[^\n]*/\/opt\/openitc\/etc\/carbon:\/etc\/carbon-c-relay/4' /opt/openitc/docker/container/graphing/docker-compose.yml
sed -i "/PARAMS=\"--listen\=localhost\ /c\PARAMS=\"--listen=127.0.0.1 \\\\" /etc/default/gearman-job-server
systemctl daemon-reload
systemctl start openitcockpit-graphing gearman-job-server
```
