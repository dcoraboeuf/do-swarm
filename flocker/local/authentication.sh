#!/bin/bash

FLOCKER_CLIENT=$1
echo "[flocker] Using Flocker client installed at: ${FLOCKER_CLIENT}"

CLUSTER_NAME=$2
echo "[flocker] Using cluster name: ${CLUSTER_NAME}"

DOMAIN_ENTRY=$3
DOMAIN_NAME=$4
echo "[flocker] Using hostname: ${DOMAIN_ENTRY}.${DOMAIN_NAME}"

source ${FLOCKER_CLIENT}/bin/activate
flocker-ca --version

echo "[flocker] Cleanup"
rm -f *.crt
rm -f *.key

echo "[flocker] Generating cluster certificates for ${CLUSTER_NAME}..."
flocker-ca initialize ${CLUSTER_NAME}

echo "[flocker] Generating control service certificates for ${DOMAIN_ENTRY}.${DOMAIN_NAME}..."
flocker-ca create-control-certificate "${DOMAIN_ENTRY}.${DOMAIN_NAME}"
