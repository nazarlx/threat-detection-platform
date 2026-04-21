provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_vpc" "honeypot_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "honeypot-vpc", Project = "threat-detection-platform" }
}

resource "aws_subnet" "honeypot_subnet" {
  vpc_id                  = aws_vpc.honeypot_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "honeypot-subnet" }
}

resource "aws_internet_gateway" "honeypot_igw" {
  vpc_id = aws_vpc.honeypot_vpc.id
  tags   = { Name = "honeypot-igw" }
}

resource "aws_route_table" "honeypot_rt" {
  vpc_id = aws_vpc.honeypot_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.honeypot_igw.id
  }
}

resource "aws_route_table_association" "honeypot_rta" {
  subnet_id      = aws_subnet.honeypot_subnet.id
  route_table_id = aws_route_table.honeypot_rt.id
}

resource "aws_security_group" "honeypot_sg" {
  name        = "honeypot-sg"
  description = "Honeypot security group"
  vpc_id      = aws_vpc.honeypot_vpc.id

  ingress {
    description = "SSH honeypot"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Real SSH admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "honeypot-sg" }
}

resource "aws_instance" "honeypot" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.honeypot_subnet.id
  vpc_security_group_ids = [aws_security_group.honeypot_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.honeypot_profile.name

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y docker.io awscli curl

# Docker
systemctl start docker
systemctl enable docker

# Cowrie з захистом
docker run -d \
  --name cowrie \
  --restart always \
  --read-only \
  --tmpfs /tmp \
  --security-opt no-new-privileges \
  -p 2222:2222 \
  cowrie/cowrie:latest

# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey=${var.tailscale_authkey} --advertise-tags=tag:honeypot

# Захист Tailscale state
chmod 600 /var/lib/tailscale/tailscaled.state
chattr +i /var/lib/tailscale/tailscaled.state

# SSH hardening
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# sudo пароль
echo "ubuntu:${var.ubuntu_password}" | chpasswd
sed -i 's/NOPASSWD:ALL/ALL/' /etc/sudoers.d/90-cloud-init-users

# UFW firewall
ufw default deny incoming
ufw allow 22/tcp
ufw allow 2222/tcp
ufw allow 41641/udp
ufw --force enable

# HEC скрипт
cat > /usr/local/bin/cowrie-to-splunk.sh << 'SCRIPT'
#!/bin/bash
SPLUNK_HEC="http://100.92.90.127:8088/services/collector"
HEC_TOKEN="${var.hec_token}"

docker logs cowrie --since 1m 2>/dev/null | grep -v "^$" | while IFS= read -r line; do
  line_escaped=$(echo "$line" | sed 's/"/\\"/g')
  curl -s -X POST "$SPLUNK_HEC" \
    -H "Authorization: Splunk $HEC_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"event\":\"$line_escaped\",\"sourcetype\":\"cowrie\"}" > /dev/null
done
SCRIPT

chmod +x /usr/local/bin/cowrie-to-splunk.sh
echo "* * * * * root /usr/local/bin/cowrie-to-splunk.sh" >> /etc/crontab
EOF

  tags = {
    Name    = "honeypot-cowrie"
    Project = "threat-detection-platform"
  }
}

resource "aws_s3_bucket" "cowrie_logs" {
  bucket = "cowrie-logs-${var.aws_account_id}"
  tags = { Name = "cowrie-logs", Project = "threat-detection-platform" }
}

resource "aws_s3_bucket_versioning" "cowrie_logs" {
  bucket = aws_s3_bucket.cowrie_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_iam_role" "honeypot_role" {
  name = "honeypot-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "honeypot_s3_policy" {
  name = "honeypot-s3-policy"
  role = aws_iam_role.honeypot_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      Resource = [aws_s3_bucket.cowrie_logs.arn, "${aws_s3_bucket.cowrie_logs.arn}/*"]
    }]
  })
}

resource "aws_iam_instance_profile" "honeypot_profile" {
  name = "honeypot-instance-profile"
  role = aws_iam_role.honeypot_role.name
}
