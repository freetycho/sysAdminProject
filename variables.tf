variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type for Minecraft server"
  default     = "t4g.small"
}

variable "minecraft_version" {
  description = "Minecraft version"
  default     = "1.21.5"
}