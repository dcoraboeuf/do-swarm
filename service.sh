#!/usr/bin/env bash

SERVICE=$1
SWARM_IP=`terraform output -no-color swarm_ip`
echo "Opening service ${SERVICE} at ${SWARM_IP}..."

case ${SERVICE} in
    vis|visual|visualizer)
        open http://${SWARM_IP}:8081
        ;;
    k|kibana)
        open http://${SWARM_IP}/app/kibana
        ;;
    g|graf|grafana)
        open http://${SWARM_IP}:3000
        ;;
esac
