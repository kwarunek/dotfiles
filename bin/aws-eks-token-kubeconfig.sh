#!/bin/bash

CALLER=`aws sts get-caller-identity | jq -r '.Arn'`
CLUSTERNAME=${1:-k8s-apps-v1}
export KUBECONFIG=/tmp/$CLUSTERNAME.kubeconfig
echo -e "CLUSTER=$CLUSTERNAME\nKUBECONFIG=$KUBECONFIG\nCALLER=$CALLER\n\n"
TOKEN=`aws eks get-token --cluster-name $CLUSTERNAME | jq '.status.token' -r`
ENDPOINT=`aws eks describe-cluster --name $CLUSTERNAME | jq -r '.cluster.endpoint'`
NAME=`head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8`

kubeconfig-by-token-generator $CLUSTERNAME-$NAME  $ENDPOINT $TOKEN 1>/dev/null
cat $KUBECONFIG
