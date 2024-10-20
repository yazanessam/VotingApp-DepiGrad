#!/bin/bash

chmod 400 gitlab_rsa
# shellcheck disable=SC2046
eval $(ssh-agent -s)
ssh-add ~/.ssh/gitlab_rsa
python3 ./set-inventory.py
ansible-galaxy collection install community.general
ansible-playbook -i inventory.ini minikube.yml | tee .minikube-playbook-output.txt


