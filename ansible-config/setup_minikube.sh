#!/bin/bash

sudo systemctl start docker
sudo systemctl enable docker

sudo apt-get update
sudo apt-get install -y apt-transport-https curl

if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
fi

sudo usermod -aG docker $USER

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube /usr/local/bin/

minikube start --driver=docker

minikube status
