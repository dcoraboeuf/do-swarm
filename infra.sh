#!/usr/bin/env bash

docker service create \
  --name=visualizer \
  --publish=8081:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  manomarks/visualizer

sudo mkdir -p /mnt/storage/ontrack &&
    docker service create \
        --name=ontrack \
        --publish=8082:8080/tcp \
        --mount=type=bind,src=/dev/urandom,dst=/dev/random \
        --mount=type=bind,src=/mnt/storage/ontrack,dst=/var/ontrack/data \
        nemerosa/ontrack:2.26.4
