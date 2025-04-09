#!/bin/bash

INSTANCE_NAME="CvCudaStack/CvCudaInstance"
REGION="ap-southeast-2"

echo "[DEBUG] INSTANCE_NAME: $INSTANCE_NAME"

IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text)

echo "[DEBUG] IP: $IP"

