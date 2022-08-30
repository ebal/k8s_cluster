#!/bin/bash
terraform plan -out terraform.out && terraform apply terraform.out
