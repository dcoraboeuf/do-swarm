#!/usr/bin/env bash

SWARM_IP=`terraform output -no-color swarm_ip`
APP=$1

PORT=$2
if [ "${PORT}" != "" ]
then
    PORT=":${PORT}"
fi

open http://${SWARM_IP}${PORT}/${APP}
