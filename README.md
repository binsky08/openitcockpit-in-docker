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

