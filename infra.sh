#!/usr/bin/env bash

# Networks

docker network create --driver overlay elk
docker network create --driver overlay proxy

# Basic visualizer

docker service create \
  --name=visualizer \
  --publish=8081:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  manomarks/visualizer

# Logging ELK

docker service create --name elasticsearch \
    --network elk \
    --publish 9200:9200 \
    --reserve-memory 500m \
    elasticsearch:2.4

# TODO Waits for elasticsearch service to be deployed

sudo mkdir -p /mnt/storage/logstash

docker service create --name logstash \
    --mount "type=bind,source=/mnt/storage/logstash,target=/conf" \
    --network elk \
    -e LOGSPOUT=ignore \
    --reserve-memory 100m \
    logstash:2.4 logstash -f /conf/logstash.conf

# TODO Waits for logstash service to be deployed

docker service create --name swarm-listener \
    --network proxy \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIF_CREATE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    -e DF_NOTIF_REMOVE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/remove \
    --constraint 'node.role==manager' \
    vfarcic/docker-flow-swarm-listener

docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --network proxy \
    -e MODE=swarm \
    -e LISTENER_ADDRESS=swarm-listener \
    vfarcic/docker-flow-proxy

# TODO Waits for swarm-listener service to be deployed
# TODO Waits for proxy service to be deployed

docker service create --name kibana \
    --network elk \
    --network proxy \
    -e ELASTICSEARCH_URL=http://elasticsearch:9200 \
    --reserve-memory 50m \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/app/kibana,/bundles,/elasticsearch \
    --label com.df.port=5601 \
    kibana:4.6

docker service create --name logspout \
    --network elk \
    --mode global \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e SYSLOG_FORMAT=rfc3164 \
    gliderlabs/logspout syslog://logstash:51415

# Monitoring

docker service create \
    --name node-exporter \
    --mode global \
    --network proxy \
    --mount "type=bind,source=/proc,target=/host/proc" \
    --mount "type=bind,source=/sys,target=/host/sys" \
    --mount "type=bind,source=/,target=/rootfs" \
    prom/node-exporter:0.12.0 \
     -collector.procfs /host/proc \
     -collector.sysfs /host/proc \
     -collector.filesystem.ignored-mount-points \
     "^/(sys|proc|dev|host|etc)($|/)"

docker service create --name cadvisor \
    --mode global \
    --network proxy \
    --mount "type=bind,source=/,target=/rootfs" \
    --mount "type=bind,source=/var/run,target=/var/run" \
    --mount "type=bind,source=/sys,target=/sys" \
    --mount "type=bind,source=/var/lib/docker,target=/var/lib/docker" \
    google/cadvisor:v0.24.1

sudo mkdir -p /mnt/storage/prometheus/data
sudo mkdir -p /mnt/storage/prometheus/conf

docker service create \
    --name prometheus \
    --network proxy \
    --publish 9090:9090 \
    --mount "type=bind,src=/mnt/storage/prometheus/conf/prometheus.yml,dst=/etc/prometheus/prometheus.yml" \
    --mount "type=bind,src=/mnt/storage/prometheus/data,dst=/prometheus" \
    prom/prometheus:v1.2.1

docker service create \
    --name grafana \
    --network proxy \
    --publish 3000:3000 \
    grafana/grafana:3.1.1

# Sample Ontrack application

sudo mkdir -p /mnt/storage/ontrack &&
    docker service create \
        --name=ontrack \
        --publish=8082:8080/tcp \
        --mount=type=bind,src=/dev/urandom,dst=/dev/random \
        --mount=type=bind,src=/mnt/storage/ontrack,dst=/var/ontrack/data \
        nemerosa/ontrack:2.26.4
