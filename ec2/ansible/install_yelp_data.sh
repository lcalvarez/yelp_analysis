#!/bin/bash

# Fail on error
sleep 30 # Give time for the ebs volume to finish setting up via user_data

# Install mongo db on the running instance
ansible-playbook mongo.yml -i hosts -b

# Download the yelp data from s3 and
# add it to mongodb
ansible-playbook yelp_data.yml -i hosts -b

