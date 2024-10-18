#!/bin/bash

export TF_VAR_vm_ssh_key=$CI_VM_SSH_PUBLIC_KEY
echo "Initializing Terraform..."
terraform init
echo "Applying Terraform configuration..."
terraform apply -auto-approve | tee terraform-output.txt
