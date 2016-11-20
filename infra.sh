#!/usr/bin/env bash

# Waiting function

function wait_for_service {
    SERVICE_NAME=$1
    while true; do
        REPLICAS=$(docker service ls | grep ${SERVICE_NAME} | awk '{print $3}')
        if [[ ${REPLICAS} == "1/1" ]]; then
            break
        else
            echo "Waiting for the ${SERVICE_NAME} service..."
            sleep 5
        fi
    done
}

################################################################################################
# Networks
################################################################################################

docker network create --driver overlay elk
docker network create --driver overlay proxy

################################################################################################
# Basic services
################################################################################################

docker service create \
  --name=visualizer \
  --publish=8081:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  manomarks/visualizer

################################################################################################
# Logging ELK
################################################################################################

docker service create --name elasticsearch \
    --network elk \
    --publish 9200:9200 \
    --reserve-memory 500m \
    elasticsearch:2.4

wait_for_service 'elasticsearch'

sudo mkdir -p /mnt/storage/logstash
sudo cp -r /tmp/conf/logstash/* /mnt/storage/logstash
sudo rm -rf /tmp/conf/logstash

docker service create --name logstash \
    --mount "type=bind,source=/mnt/storage/logstash,target=/conf" \
    --network elk \
    -e LOGSPOUT=ignore \
    --reserve-memory 100m \
    logstash:2.4 logstash -f /conf/logstash.conf

wait_for_service 'logstash'

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

wait_for_service 'swarm-listener'
wait_for_service 'proxy'

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

################################################################################################
# Monitoring
################################################################################################

docker service create \
    --name node-exporter \
    --mode global \
    --network proxy \
    --mount "type=bind,source=/proc,target=/host/proc" \
    --mount "type=bind,source=/sys,target=/host/sys" \
    --mount "type=bind,source=/,target=/rootfs" \
    --mount "type=bind,source=/etc/hostname,target=/etc/host_hostname" \
    -e HOST_HOSTNAME=/etc/host_hostname \
    basi/node-exporter:v0.1.1 \
        -collector.procfs /host/proc \
        -collector.sysfs /host/proc \
        -collector.filesystem.ignored-mount-points "^/(sys|proc|dev|host|etc)($|/)" \
        -collector.textfile.directory /etc/node-exporter/ \
        -collectors.enabled="conntrack,diskstats,entropy,filefd,filesystem,loadavg,mdadm,meminfo,netdev,netstat,stat,textfile,time,vmstat,ipvs"

docker service create --name cadvisor \
    --mode global \
    --network proxy \
    --mount "type=bind,source=/,target=/rootfs" \
    --mount "type=bind,source=/var/run,target=/var/run" \
    --mount "type=bind,source=/sys,target=/sys" \
    --mount "type=bind,source=/var/lib/docker,target=/var/lib/docker" \
    google/cadvisor:v0.24.1

wait_for_service 'node-exporter'
wait_for_service 'cadvisor'

sudo mkdir -p /mnt/storage/prometheus/data
sudo mkdir -p /mnt/storage/prometheus/conf
sudo cp -r /tmp/conf/prometheus/conf/* /mnt/storage/prometheus/conf
sudo rm -rf /tmp/conf/prometheus/conf

docker service create \
    --name prometheus \
    --network proxy \
    --publish 9090:9090 \
    --mount "type=bind,src=/mnt/storage/prometheus/conf/prometheus.yml,dst=/etc/prometheus/prometheus.yml" \
    --mount "type=bind,src=/mnt/storage/prometheus/data,dst=/prometheus" \
    prom/prometheus:v1.2.1

wait_for_service 'prometheus'

docker service create \
    --name grafana \
    --name elk \
    --network proxy \
    --publish 3000:3000 \
    grafana/grafana:3.1.1

wait_for_service 'grafana'
