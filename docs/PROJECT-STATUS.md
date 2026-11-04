# Project delivery status

## Existing resources confirmed by the user
- AWS region: ap-south-1.
- Account ID: 632843870789.
- ECR repository: devops-ec2-hello-world.
- Existing ECR image: v3, digest `sha256:09cfcec1054214964f68782fce4db79c24075f95e2e6240433fe644cbf600e9b`.
- GitHub repo: prayasjat/devops-ec2-project.
- GitHub repository ID: 1439686976; owner ID: 215667995.
- GitHub repo was previously public; change it to private before deploy.
- IAM console previously showed zero OIDC providers.
- No controlled domain was confirmed.

## Included in this bundle
- Flask app, tests, Dockerfile.
- GitHub Actions CI/CD workflow.
- Terraform S3 backend bootstrap.
- Terraform main infrastructure, IAM OIDC role, VPC, ALB, private EC2 ASG, SSM, CloudWatch.
- EC2 bootstrap and rollback deployment script.

## Not yet executed
No AWS resource creation or GitHub workflow execution is claimed by this bundle. The user must apply Terraform, configure the GitHub repository variable, push the workflow, and verify the resulting AWS deployment.
