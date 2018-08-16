#!/bin/bash
yum update --assumeyes
yum-config-manager --enable rhui-REGION-rhel-server-extras
yum install docker --assumeyes
systemctl enable --now docker
docker run --rm --name webapp --publish 80:8000 wadadli/webapp:1.2.0 --user ${db_user} --password ${db_pass} --table ${db_table} --hostname ${db_endpoint}
