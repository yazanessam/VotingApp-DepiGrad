#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Install dependencies
echo "Installing dependencies..."
apt-get update -y
apt-get install -y apt-transport-https curl docker.io

# Add user to Docker group
echo "Adding user to Docker group..."
usermod -aG docker "$USER"

# Download and install Minikube
echo "Downloading and installing Minikube..."
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
mv minikube /usr/local/bin/

# Start Minikube with Docker driver
echo "Starting Minikube with Docker driver..."
minikube start --driver=docker

echo "Minikube setup completed successfully!"
