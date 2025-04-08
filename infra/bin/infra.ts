import * as dotenv from 'dotenv';
import * as path from 'path';
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

import * as cdk from 'aws-cdk-lib';
import { CvCudaStack } from '../lib/cv-cuda-stack';

const app = new cdk.App();

const region = process.env.AWS_REGION;
const amiId = process.env.EC2_AMI_ID;
const account = process.env.CDK_DEFAULT_ACCOUNT || process.env.AWS_ACCOUNT_ID;

if (!region || !amiId) {
  throw new Error("❌ You must set AWS_REGION and EC2_AMI_ID in your environment.");
}

new CvCudaStack(app, 'CvCudaStack', {
  env: { region, account },
  region,
  amiId,
});

