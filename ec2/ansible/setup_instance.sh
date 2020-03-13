#!/bin/bash -e

# Fail on error
sleep 30 # Give time for the ebs volume to finish setting up via user_data

# Install pip packages
ansible-playbook install_pip_packages.yml -i hosts -b

# Install mongo db on the running instance
ansible-playbook mongo.yml -i hosts -b

# Download the yelp data from s3 and
# add it to mongodb
ansible-playbook yelp_data.yml -i hosts -b

# Install jupyterhu
ansible-playbook jupyter.yml -i hosts -b

# Download jupyter notebook with data analysis
ansible-playbook download_jupyter_notebook.yml -i hosts -b
