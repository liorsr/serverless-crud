#!/bin/bash

# Render HTML template and zip lambda function
python3 scripts/deployment_prep.py

# Build and deploy
terraform init
terraform plan
terraform apply -auto-approve
