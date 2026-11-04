terraform {
  backend "s3" {
    bucket       = "devops-ec2-project-tfstate-632843870789-ap-south-1"
    key          = "devops-ec2-project/prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
