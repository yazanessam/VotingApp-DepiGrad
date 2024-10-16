#!/bin/bash

systemctl start docker
systemctl enable docker

apt-get update
apt-get install -y apt-transport-https curl

if ! command -v docker &> /dev/null; then
    apt-get install -y docker.io
fi

usermod -aG docker $USER

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube /usr/local/bin/

minikube start --driver=docker

minikube status
