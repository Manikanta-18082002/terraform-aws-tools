module "jenkins" { # Created Jenkins instance EC2
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-tf"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-00fdfc2b0e8a3e6e9"] #replace your SG
  subnet_id = "subnet-0e273ca043101f2d5" #replace your Subnet (us-east-1 --> Default Subnet)
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins.sh")
  tags = {
    Name = "jenkins-tf"
  }
}

module "jenkins_agent" { # Created Jenkins - Agent instance
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-00fdfc2b0e8a3e6e9"] #replace your SG
  # convert StringList to list and get first element
  subnet_id = "subnet-0e273ca043101f2d5" #replace your Subnet
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}

resource "aws_key_pair" "tools" {
  key_name   = "tools"
  # you can paste the public key directly like this
  #public_key = "ssh-....."
  public_key = file("C:/devops/.ssh/tools.pub")
  # ~ means windows home directory
}

module "nexus" { // UBUNTU OS
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t3.medium"
  vpc_security_group_ids = ["sg-00fdfc2b0e8a3e6e9"]
  # convert StringList to list and get first element
  subnet_id = "subnet-0e273ca043101f2d5"
  ami = data.aws_ami.nexus_ami_info.id
  key_name = aws_key_pair.tools.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "nexus"
  }
} // TO login --> ssh -i /c/devops/.ssh/tools ubuntu@ip | copy path for pass --> Paste --> Enable anonymous access -- exit

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "nexus"
      type    = "A"
      ttl     = 1
      allow_overwrite = true
      records = [
        module.nexus.private_ip # Creating a record nexus.dawsmani.site (And giving private IP inside record)
      ]
      allow_overwrite = true
    }
  ]

}