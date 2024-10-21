#!/bin/bash
cat > worker-deployment.yml <<EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: worker
  name: worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
      - image: $CI_REGISTRY/depi9980437/voting-app/$CI_ENV/worker:$CI_IMAGE_VER
        name: worker
EOL