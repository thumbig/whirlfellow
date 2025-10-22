############################################
# PROVIDER
############################################
provider "aws" {
  region = "us-east-1"
}

############################################
# KEY PAIR
############################################
resource "aws_key_pair" "demo_key" {
  key_name   = "hello-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

############################################
# SECURITY GROUP
############################################
resource "aws_security_group" "hello_sg" {
  name_prefix = "hello-sg-"

  # Allow HTTP (optional)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Node.js app port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH
  ingress {
    description = "Allow SSH for debugging"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "whirlfellow-sg"
  }
}

############################################
# LATEST AMAZON LINUX 2023 AMI
############################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

############################################
# EC2 INSTANCE
############################################
resource "aws_instance" "hello_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.demo_key.key_name
  security_groups         = [aws_security_group.hello_sg.name]
  user_data_replace_on_change = true

  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail
exec > /var/log/whirlfellow-init.log 2>&1

echo "=== STARTING INIT ==="

# Update and install packages
dnf update -y
dnf install -y git curl

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

echo "Node version: $(node -v || true)"
echo "NPM version: $(npm -v || true)"

# Clone your repo
cd /home/ec2-user
git clone https://github.com/thumbig/whirlfellow.git || exit 1
cd whirlfellow/backend
npm install

# Start server on port 3000
nohup node server.js --port 3000 > /home/ec2-user/app.log 2>&1 &

echo "=== SETUP COMPLETE ==="
EOF

  tags = {
    Name = "whirlfellow"
  }
}

############################################
# OUTPUTS
############################################
output "public_ip" {
  description = "Public IP of the deployed EC2"
  value       = aws_instance.hello_instance.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.hello_instance.public_ip}"
}

output "app_url" {
  value = "http://${aws_instance.hello_instance.public_ip}:3000/api/hello"
}
