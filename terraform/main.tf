provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "demo_key" {
  key_name   = "hello-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "hello_sg" {
  name_prefix = "hello-sg-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get latest Amazon Linux 2 AMI dynamically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "hello_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.demo_key.key_name
  security_groups = [aws_security_group.hello_sg.name]

    user_data = <<-EOF
      #!/bin/bash
      yum update -y
      curl -sL https://rpm.nodesource.com/setup_18.x | bash -
      yum install -y nodejs git
      cd /home/ec2-user
      git clone https://github.com/thumbig/whirlfellow.git || exit 1
      cd whirlfellow/backend
      npm install
      # run Node on port 80 explicitly
      nohup node server.js > app.log 2>&1 &
    EOF

  tags = {
    Name = "whirlfellow"
  }
}

output "public_ip" {
  value = aws_instance.hello_instance.public_ip
}
