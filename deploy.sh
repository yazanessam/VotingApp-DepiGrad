#!/bin/bash
sh ./build-result-deployment.sh
sh ./build-vote-deployment.sh
sh ./build-worker-deployment.sh
kubectl apply -f ./namespaces.yaml
kubectl apply -f ./result-deployment.yml -n "$CI_ENV"
kubectl apply -f ./vote-deployment.yml -n "$CI_ENV"
kubectl apply -f ./worker-deployment.yml -n "$CI_ENV"