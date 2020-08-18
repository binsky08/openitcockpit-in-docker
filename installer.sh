#!/bin/bash

if [ ! -f /opt/openitc/.installed ]; then
    systemctl set-default multi-user.target
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https curl gnupg2 ca-certificates cron software-properties-common
    add-apt-repository universe
    DEBIAN_FRONTEND=noninteractive curl https://packages.openitcockpit.io/repokey.txt | apt-key add -
    echo "deb https://packages.openitcockpit.io/openitcockpit/$(lsb_release -sc)/stable $(lsb_release -sc) main" > /etc/apt/sources.list.d/openitcockpit.list
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y openitcockpit
    mkdir -p /run/php
    systemctl start docker mysql php7.3-fpm nginx cron redis
    docker load < /opt/openitc/docker/images/docker-graphing.tar.bz2
    sed -e '/ExecStartPre/ s/^#*/#/' -i /lib/systemd/system/openitcockpit-graphing.service
    sed -i "/image:\ openitcockpit\/carbon-c-relay:latest/c\\ \ \ \ image:\ mist\/carbon-c-relay" /opt/openitc/docker/container/graphing/docker-compose.yml
    sed -i ':a;N;$!ba;s/\/opt\/openitc\/etc\/carbon:\/etc\/carbon[^\n]*/\/opt\/openitc\/etc\/carbon:\/etc\/carbon-c-relay/4' /opt/openitc/docker/container/graphing/docker-compose.yml
    sed -i "/PARAMS=\"--listen\=localhost\ /c\PARAMS=\"--listen=127.0.0.1 \\\\" /etc/default/gearman-job-server
    systemctl daemon-reload
    systemctl start sudo_server gearman_worker oitc_cmd statusengine gearman-job-server push_notification nodejs_server openitcockpit-graphing
    /opt/openitc/frontend/SETUP.sh
    touch /opt/openitc/.installed
    ip a
fi
