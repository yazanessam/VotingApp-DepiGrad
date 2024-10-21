#!/bin/bash
sh ./k8s-specifications/build-deployments/build-result-deployment.sh
sh ./k8s-specifications/build-deployments/build-vote-deployment.sh
sh ./k8s-specifications/build-deployments/build-worker-deployment.sh
kubectl apply -f ./k8s-specifications/build-deployments/namespaces.yaml
kubectl apply -f ./k8s-specifications/build-deployments/result-deployment.yml -n "$CI_ENV"
kubectl apply -f ./k8s-specifications/build-deployments/vote-deployment.yml -n "$CI_ENV"
kubectl apply -f ./k8s-specifications/build-deployments/worker-deployment.yml -n "$CI_ENV"
