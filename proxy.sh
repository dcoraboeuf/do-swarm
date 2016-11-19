#!/usr/bin/env bash

SWARM_IP=`terraform output -no-color swarm_ip`
APP=$1

open http://${SWARM_IP}/${APP}
