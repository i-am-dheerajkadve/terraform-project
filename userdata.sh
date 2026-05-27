#!/bin/bash

apt update -y

apt install docker.io -y

systemctl start docker
systemctl enable docker

curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

mkdir /app

cat <<EOF > /app/docker-compose.yml
version: '3'

services:

  frontend:
    image: harshjswl/k8s-frontend
    container_name: frontend
    ports:
      - "3000:80"
    environment:
      VITE_API_URL: http://${EC2_IP}:8080
  backend:
    image: harshjswl/k8s-backend
    container_name: backend
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://${RDS_ENDPOINT}:5432/appdb
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: postgres123

EOF

cd /app

docker compose up -d
