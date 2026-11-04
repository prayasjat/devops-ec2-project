variable "aws_region" {
  type        = string
  description = "AWS region."
  default     = "ap-south-1"
}

variable "app_name" {
  type        = string
  description = "Application name used in resource names and tags."
  default     = "devops-ec2-project"
}

variable "ecr_repository_name" {
  type        = string
  description = "Existing ECR repository name."
  default     = "devops-ec2-hello-world"
}

variable "initial_image_uri" {
  type        = string
  description = "Existing known-good ECR image URI pinned by digest for initial deployment."
  default     = "632843870789.dkr.ecr.ap-south-1.amazonaws.com/devops-ec2-hello-world@sha256:09cfcec1054214964f68782fce4db79c24075f95e2e6240433fe644cbf600e9b"
}

variable "github_owner" {
  type        = string
  default     = "prayasjat"
  description = "GitHub repository owner."
}

variable "github_repository" {
  type        = string
  default     = "devops-ec2-project"
  description = "GitHub repository name."
}

variable "github_owner_id" {
  type        = string
  default     = "215667995"
  description = "Immutable GitHub owner ID."
}

variable "github_repository_id" {
  type        = string
  default     = "1439686976"
  description = "Immutable GitHub repository ID."
}

variable "github_branch" {
  type        = string
  default     = "main"
  description = "Branch permitted to assume the publishing/deployment role."
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Starter instance size; select production capacity after load testing."
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "nat_gateway_per_az" {
  type        = bool
  default     = true
  description = "One NAT Gateway per AZ for AZ-resilient private-subnet egress. This increases cost."
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "Optional DNS name for public ACM certificate and HTTPS. Requires a Route 53 hosted zone."
}

variable "route53_zone_id" {
  type        = string
  default     = ""
  description = "Route 53 public hosted zone ID for domain_name."
}

variable "log_retention_days" {
  type    = number
  default = 14
}
