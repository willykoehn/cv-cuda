#!/bin/bash

INSTANCE_NAME="CvCudaStack/CvCudaInstance"
REGION="ap-southeast-2"
KEY_PATH="$HOME/.ssh/my-gpu-key.pem"
LOCAL_PATH="$HOME/cv-cuda"
REMOTE_PATH="~/cv-cuda"

get_instance_id() {
  aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text
}

get_ip() {
  aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text
}

start_instance() {
  local instance_id
  instance_id=$(get_instance_id)
  echo "[INFO] Starting instance $instance_id..."
  aws ec2 start-instances --region "$REGION" --instance-ids "$instance_id"
  echo "[INFO] Waiting for instance to enter 'running' state..."
  aws ec2 wait instance-running --region "$REGION" --instance-ids "$instance_id"
  echo "[INFO] Instance is running."
  get_ip
}

stop_instance() {
  local instance_id
  instance_id=$(get_instance_id)
  echo "[INFO] Stopping instance $instance_id..."
  aws ec2 stop-instances --region "$REGION" --instance-ids "$instance_id"
  echo "[INFO] Waiting for instance to stop..."
  aws ec2 wait instance-stopped --region "$REGION" --instance-ids "$instance_id"
  echo "[INFO] Instance has stopped."
}

ssh_ec2() {
  local ip=$(get_ip)
  echo "[INFO] Connecting to $ip..."
  ssh -i "$KEY_PATH" ubuntu@"$ip"
}

sync_code() {
  local ip=$(get_ip)
  echo "[INFO] Syncing code to $ip..."
  rsync -avz --exclude ".git" --exclude "node_modules" \
    -e "ssh -i $KEY_PATH" "$LOCAL_PATH"/ ubuntu@"$ip":"$REMOTE_PATH"
}

deploy_and_ssh() {
  sync_code && ssh_ec2
}

# === Entry point ===

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 {get_ip|get_instance_id|start_instance|stop_instance|ssh_ec2|sync_code|deploy_and_ssh}"
  exit 1
fi

if declare -f "$1" > /dev/null; then
  "$@"
else
  echo "Unknown command: $1"
  echo "Available commands: get_ip, get_instance_id, start_instance, stop_instance, ssh_ec2, sync_code, deploy_and_ssh"
  exit 1
fi
