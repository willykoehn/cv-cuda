#!/bin/bash

# Load environment variables from project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
set -a
source "$PROJECT_ROOT/.env"
set +a

# Lowercase internal vars (env vars stay ALL_CAPS)
instance_name="CvCudaStack/CvCudaInstance"
region="${AWS_REGION}"
key_path="$HOME/.ssh/${EC2_KEY_NAME}.pem"
local_path="$HOME/cv-cuda"
remote_path="~/cv-cuda"

get_instance_id() {
  aws ec2 describe-instances \
    --region "$region" \
    --filters "Name=tag:Name,Values=$instance_name" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text
}

get_ip() {
  aws ec2 describe-instances \
    --region "$region" \
    --filters "Name=tag:Name,Values=$instance_name" \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text
}

start_instance() {
  local instance_id
  instance_id=$(get_instance_id)
  echo "[INFO] Starting instance $instance_id..."
  aws ec2 start-instances --region "$region" --instance-ids "$instance_id"
  echo "[INFO] Waiting for instance to enter 'running' state..."
  aws ec2 wait instance-running --region "$region" --instance-ids "$instance_id"
  echo "[INFO] Instance is running."
  get_ip
}

stop_instance() {
  local instance_id
  instance_id=$(get_instance_id)
  echo "[INFO] Stopping instance $instance_id..."
  aws ec2 stop-instances --region "$region" --instance-ids "$instance_id"
  echo "[INFO] Waiting for instance to stop..."
  aws ec2 wait instance-stopped --region "$region" --instance-ids "$instance_id"
  echo "[INFO] Instance has stopped."
}

ssh_ec2() {
  local ip
  ip=$(get_ip)
  echo "[INFO] Connecting to $ip..."
  ssh -i "$key_path" ubuntu@"$ip"
}

sync_code() {
  local ip
  ip=$(get_ip)
  echo "[INFO] Syncing code to $ip..."
  rsync -avz --exclude ".git" --exclude "node_modules" \
    -e "ssh -i $key_path" "$local_path"/ ubuntu@"$ip":"$remote_path"
}

deploy_and_ssh() {
  sync_code && ssh_ec2
}

stop_self() {
  echo "[INFO] Requesting EC2 instance to shut itself down..."
  sudo shutdown -h now
}

# === Entry point ===

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 {get_ip|get_instance_id|start_instance|stop_instance|ssh_ec2|sync_code|deploy_and_ssh|stop_self}"
  exit 1
fi

if declare -f "$1" > /dev/null; then
  "$@"
else
  echo "Unknown command: $1"
  echo "Available commands: get_ip, get_instance_id, start_instance, stop_instance, ssh_ec2, sync_code, deploy_and_ssh"
  exit 1
fi

