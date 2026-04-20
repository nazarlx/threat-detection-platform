variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "your_ip" {
  description = "Your home IP for SSH access (format: x.x.x.x/32)"
  type        = string
}

variable "key_name" {
  description = "AWS EC2 Key Pair name"
  default     = "honeypot-key"
}

variable "splunk_ip" {
  description = "Splunk server IP address"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID for S3 bucket naming"
  type        = string
}
