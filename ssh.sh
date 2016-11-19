#!/usr/bin/env bash

SWARM_USER=`terraform output -no-color swarm_user`

ssh \
    -o StrictHostKeyChecking=no \
    -o NoHostAuthenticationForLocalhost=yes \
    -o UserKnownHostsFile=/dev/null \
    -i do-key \
    ${SWARM_USER}@$1
