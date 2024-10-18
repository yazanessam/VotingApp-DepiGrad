import json
import configparser
import os

# Load the JSON output
with open('../Terraform/terraform-output.json', 'r') as file:
    data = json.load(file)

# Create a ConfigParser object
config = configparser.ConfigParser(allow_no_value=True)
ssh_user = os.environ.get('CI_TF_USERNAME', 'azureuser')  # Default to 'azureuser' if not set

# Retrieve the public IP from the Terraform output
public_ip = data['public_ip']['value']

# Add the public IP to the Ansible inventory under the 'k8s' section
config['minikube'] = {
    "ansible_host": public_ip,
    "ansible_user": ssh_user,
    "ansible_ssh_private_key_file": "./Gitlab_rsa"
}

# Common SSH arguments
config['all:vars'] = {
    "ansible_ssh_common_args": "'-o StrictHostKeyChecking=no'"
}

# Write the data to an INI file
with open('inventory.ini', 'w') as configfile:
    config.write(configfile)

print(f"Public IP {public_ip} saved to inventory.ini")
