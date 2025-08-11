# variables.tf content (paste into variables.tf or add to top of this file)

# --- variables ---

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "key_name" {
  description = "Name for the EC2 key pair to create"
  type        = string
  default     = "my-aws-wg"
}

variable "public_key_path" {
  description = "Path to the public key file (e.g. ~/.ssh/id_rsa.pub)"
  type        = string
  default     = "/home/valentin/my-aws-wg.pub"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (default: your IP /32)"
  type        = string
  default     = "0.0.0.0/0"
}
