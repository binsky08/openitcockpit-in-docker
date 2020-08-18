# openITCOCKPIT in Docker

## Setup

The container should get an automatically bridged ip address.
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

Login and register instance with the current community license key: 0dc0d951-e34e-43d0-a5a5-a690738e6a49


## Handling

### Command line login
`docker exec -it oitc /bin/bash`


### Backups

Use the frontend backup and restore functionality at https://172.17.0.3/#!/backups/index
Download a backup file from your old installation, copy it into the container and start a restore.
`docker cp openitcockpit_dump_2020-08-18_12-05-00.sql oitc:/opt/openitc/nagios/backup/`

After that logout and login with you user from the restored instance.
You may have to go to 'Manage User Roles', edit every role and click 'Update user role'.


### Add port mapping to the existing container

#### v1
```
systemctl stop docker
oitcID=`docker ps -aqf "name=oitc"`
nano /var/lib/docker/containers/${oitcID}*/hostconfig.json
systemctl start docker
```

#### v2
```
docker stop oitc
docker commit oitc oitc2
docker rm oitc
docker run -d --name oitc \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --mount type=bind,source="$(pwd)"/installer.sh,target=/installer.sh \
    --security-opt seccomp=unconfined \
    --privileged \
    oitc2
```

## Troubleshooting

### Fix problems with the gearmand and docker
These commands were executed during the custom openitcockpit installation.

Due to the openitcockpit config generator, the customizations will be overwritten.
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
