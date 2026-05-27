#!/bin/bash

apt update -y

apt install docker.io -y

systemctl start docker
systemctl enable docker

curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
