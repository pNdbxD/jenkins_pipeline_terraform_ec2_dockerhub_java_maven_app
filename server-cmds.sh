#!/usr/bin/env bash

export DOCKER_IMAGE=$1
export DOCKER_USER=$2
export DOCKER_PWD=$3


echo $DOCKER_PWD | docker login --username $DOCKER_USER --password-stdin
docker compose -f docker-compose.yaml up -d
echo "Server is running!!!"


