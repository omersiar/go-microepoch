#!/bin/bash

# get kubectl binary from google
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
mkdir ${HOME}/.kube
# set configuration for kubectl
kubectl config set-cluster googlecloud --server=https://35.242.211.169 --certificate-authority=gcp.crt --embed-certs
kubectl config set-credentials travis-app-deployer --token=$KUBE_PROD_DEPLOYER
kubectl config set-credentials travis-testapp-deployer --token=$KUBE_TEST_DEPLOYER
kubectl config set-context production --cluster=googlecloud --user=travis-app-deployer --namespace=production
kubectl config set-context staging --cluster=googlecloud --user=travis-testapp-deployer --namespace=staging