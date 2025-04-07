#!/bin/bash

set -e

echo "Updating system and installing build tools..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y build-essential cmake unzip curl git

echo "Verifying CUDA installation..."
nvcc --version || echo "CUDA not found. Make sure you're using a Deep Learning AMI."

echo "Setup complete. Ready to build your C++/CUDA code."

