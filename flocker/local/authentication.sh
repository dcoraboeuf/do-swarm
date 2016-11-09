#!/bin/bash

FLOCKER_CLIENT=$1
echo "[flocker] Using Flocker client installed at: ${FLOCKER_CLIENT}"

FLOCKER_CLIENT_NAME=$2
echo "[flocker] Flocker client name: ${FLOCKER_CLIENT_NAME}"

CLUSTER_NAME=$3
echo "[flocker] Using cluster name: ${CLUSTER_NAME}"

DOMAIN_ENTRY=$4
DOMAIN_NAME=$5
echo "[flocker] Using hostname: ${DOMAIN_ENTRY}.${DOMAIN_NAME}"

source ${FLOCKER_CLIENT}/bin/activate
echo "[flocker] Version: $(flocker-ca --version)"

echo "[flocker] Cleanup"
rm -f *.crt
rm -f *.key
rm -rf flocker-ca-node
rm -rf flocker-ca-client
rm -rf flocker-ca-client-plugin

echo "[flocker] Generating cluster certificates for ${CLUSTER_NAME}..."
flocker-ca initialize ${CLUSTER_NAME}

echo "[flocker] Generating control service certificates for ${DOMAIN_ENTRY}.${DOMAIN_NAME}..."
flocker-ca create-control-certificate "${DOMAIN_ENTRY}.${DOMAIN_NAME}"

echo "[flocker] Generating node authentication certificates..."
mkdir -p flocker-ca-node
flocker-ca create-node-certificate --outputpath flocker-ca-node
mv flocker-ca-node/*.crt flocker-ca-node/node.crt
mv flocker-ca-node/*.key flocker-ca-node/node.key

echo "[flocker] Generating API client certificate for ${FLOCKER_CLIENT_NAME}..."
mkdir -p flocker-ca-client
flocker-ca create-api-certificate --outputpath flocker-ca-client ${FLOCKER_CLIENT_NAME}

echo "[flocker] Generating API client certificate for the plugin..."
mkdir -p flocker-ca-client-plugin
flocker-ca create-api-certificate --outputpath flocker-ca-client-plugin plugin
