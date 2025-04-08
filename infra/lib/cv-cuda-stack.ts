import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps } from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';
import * as path from 'path';
import * as fs from 'fs';

interface CvCudaStackProps extends StackProps {
  region: string;
  amiId: string;
}

export class CvCudaStack extends Stack {
  constructor(scope: Construct, id: string, props: CvCudaStackProps) {
    super(scope, id, props);

    // Get key name from env var
    const keyName = process.env.EC2_KEY_NAME;
    if (!keyName) {
      throw new Error("❌ You must set the EC2_KEY_NAME environment variable before deploying.");
    }

    // VPC
    const vpc = new ec2.Vpc(this, 'CvCudaVpc', {
      maxAzs: 2,
    });

    // Security Group
    const sg = new ec2.SecurityGroup(this, 'CvCudaSG', {
      vpc,
      allowAllOutbound: true,
      description: 'Allow SSH and HTTP',
    });
    sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(22), 'Allow SSH access');
    sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'Allow HTTP access');

    // Deep Learning AMI with CUDA
    const ami = ec2.MachineImage.genericLinux({
      [props.region]: props.amiId,
    });

    // Load setup.sh from scripts dir
    const userData = ec2.UserData.forLinux();
    const scriptPath = path.join(__dirname, '../scripts/setup.sh');
    const script = fs.readFileSync(scriptPath, 'utf8');
    userData.addCommands(script);

    // EC2 instance
    const instance = new ec2.Instance(this, 'CvCudaInstance', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.G4DN, ec2.InstanceSize.XLARGE),
      machineImage: ami,
      securityGroup: sg,
      keyName,
      userData,
      vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC }, // 👈 forces public subnet
      associatePublicIpAddress: true, // 👈 critical line
    });
  }
}

