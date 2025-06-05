terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2" # Change to your preferred region
}

# Create a VPC
resource "aws_vpc" "minecraft_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Minecraft-VPC"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id

  tags = {
    Name = "Minecraft-IGW"
  }
}

# Create a public subnet
resource "aws_subnet" "minecraft_subnet" {
  vpc_id            = aws_vpc.minecraft_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a" # Change to match your region

  tags = {
    Name = "Minecraft-Subnet"
  }
}

# Create a route table
resource "aws_route_table" "minecraft_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }

  tags = {
    Name = "Minecraft-RouteTable"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "minecraft_rta" {
  subnet_id      = aws_subnet.minecraft_subnet.id
  route_table_id = aws_route_table.minecraft_rt.id
}

# Create a security group for the Minecraft server
resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-security-group"
  description = "Allow Minecraft and SSH traffic"
  vpc_id      = aws_vpc.minecraft_vpc.id

  # Allow SSH access from specific IP ranges (EC2 Instance Connect)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["18.237.140.160/29"] # EC2 Instance Connect for us-west-2
  }

  # Allow Minecraft server traffic
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Minecraft-SecurityGroup"
  }
}

# Create an EC2 instance for the Minecraft server
resource "aws_instance" "minecraft_server" {
  ami           = "ami-05d2ed97ce7162747"
  instance_type = "t4g.small"
  subnet_id     = aws_subnet.minecraft_subnet.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = "LabInstanceProfile"

  # Root volume configuration
  root_block_device {
    volume_size = 8 # 8GB root volume
    volume_type = "gp3"
  }

  # User data script to install and configure Minecraft server
  user_data = <<-EOF
              #!/bin/bash
              # Install Java
              sudo yum install -y java-21-amazon-corretto-headless
              
              # Create Minecraft directories
              mkdir -p /opt/minecraft/server
              cd /opt/minecraft/server
              
              # Download Minecraft server
              wget https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar
              
              # Accept EULA
              echo "eula=true" > eula.txt
              
              # Create start script
              cat > start << 'EOL'
              #!/bin/bash
              java -Xmx1300M -Xms1300M -jar server.jar nogui
              EOL
              chmod +x start
              
              # Create stop script
              cat > stop << 'EOL'
              #!/bin/bash
              kill -9 $(ps -ef | pgrep -f "java")
              EOL
              chmod +x stop
              
              # Create systemd service for auto-start
              cat > /etc/systemd/system/minecraft.service << 'EOL'
              [Unit]
              Description=Minecraft Server
              After=network.target
              
              [Service]
              User=root
              WorkingDirectory=/opt/minecraft/server
              ExecStart=/opt/minecraft/server/start
              ExecStop=/opt/minecraft/server/stop
              Restart=always
              
              [Install]
              WantedBy=multi-user.target
              EOL
              
              # Enable and start the service
              systemctl daemon-reload
              systemctl enable minecraft.service
              systemctl start minecraft.service
              EOF

  tags = {
    Name = "Minecraft-Server"
  }
}

# Create Elastic IP for the Minecraft server
resource "aws_eip" "minecraft_eip" {
  instance = aws_instance.minecraft_server.id
  vpc      = true

  tags = {
    Name = "Minecraft-EIP"
  }
}

# Output the public IP address for connecting to the Minecraft server
output "minecraft_server_ip" {
  value = aws_eip.minecraft_eip.public_ip
  description = "Public IP address of the Minecraft server"
}