#!/bin/bash
cat > vote-deployment.yml <<EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: vote
  name: vote
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vote
  template:
    metadata:
      labels:
        app: vote
    spec:
      containers:
      - image: $CI_REGISTRY/depi9980437/voting-app/$CI_ENV/vote:$CI_IMAGE_VER
        name: vote
        ports:
        - containerPort: 80
          name: vote
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: vote
  name: vote
spec:
  type: NodePort
  ports:
  - name: "vote-service"
    port: 5000
    targetPort: 80
    nodePort: 31000
  selector:
    app: vote
  
EOL