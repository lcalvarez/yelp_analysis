#!/bin/bash

# Download the terraform zip file
wget https://releases.hashicorp.com/terraform/0.12.20/terraform_0.12.20_linux_amd64.zip

# Unzip zipped file
unzip terraform_0.12.20_linux_amd64.zip

# Check terraform version
terraform version
