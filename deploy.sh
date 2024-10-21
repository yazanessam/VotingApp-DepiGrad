#!/bin/bash
./k8s-specifications/build-deployments/build-result-deployment.sh
./k8s-specifications/build-deployments/build-vote-deployment.sh
./k8s-specifications/build-deployments/build-worker-deployment.sh
kubectl apply -f ./k8s-specifications/namespaces.yaml
kubectl apply -f ./k8s-specifications/result-deployment.yml -n "$CI_ENV"
kubectl apply -f ./k8s-specifications/vote-deployment.yml -n "$CI_ENV"
kubectl apply -f ./k8s-specifications/worker-deployment.yml -n "$CI_ENV"
