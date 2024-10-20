#!/bin/bash

chmod 400 gitlab_rsa
python3 --version
pip install --upgrade ansible
python3 ./set-inventory.py
ansible-galaxy collection install community.general
ansible-playbook -i inventory.ini minikube.yml | tee .minikube-playbook-output.txt


