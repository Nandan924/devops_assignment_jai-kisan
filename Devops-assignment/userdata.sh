#!/bin/bash

# here we are featching Private IP & Hostname.
private_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
hostname=$(curl -s http://169.254.169.254/latest/meta-data/hostname)

# here we are creating the file and storing the above ip and hostname.
filename="ip_info.txt"
echo "Private IP: $private_ip" >> "$filename"
echo "Hostname: $hostname" >> "$filename"

# Here we are installing AWS CLI in ubuntu
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt install unzip -y
    sudo unzip awscliv2.zip
    sudo ./aws/install
fi



# Uploading the file to our 3rd S3 bucket
bucket_name="peace-prefix-3"
aws s3 cp "$filename" "s3://$bucket_name/$filename"