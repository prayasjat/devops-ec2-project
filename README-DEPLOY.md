# AWS EC2 Docker CI/CD project

This overlay replaces the previous partial workflow and adds Terraform infrastructure. It uses:

- GitHub Actions for CI and release orchestration.
- GitHub OIDC for short-lived AWS role credentials.
- Existing private ECR repository `devops-ec2-hello-world`.
- Terraform-managed VPC, two-AZ public ALB, private EC2 Auto Scaling Group, IAM, SSM Parameter Store and CloudWatch Logs.
- AWS Systems Manager Run Command for a serial deployment across tagged EC2 instances. No CodeDeploy dependency.
- Docker on EC2, with a per-instance rollback if the new image fails `/health`.
- Optional public ACM HTTPS if a domain and Route 53 public hosted zone are supplied.

## Important constraints

1. This creates billable AWS resources. Two NAT Gateways, an ALB, and two EC2 instances incur ongoing charges. Destroy the stack when finished if it is not needed.
2. `t3.micro` is a demo starting size, not a production capacity recommendation. Load-test and right-size before claiming production readiness.
3. `nat_gateway_per_az = true` gives AZ-local egress but has higher cost. Setting it false uses one NAT Gateway and creates an egress single point of failure.
4. Without a domain you control and a Route 53 public hosted zone, Terraform creates an HTTP listener only. The ALB's default `amazonaws.com` hostname cannot receive a publicly trusted ACM certificate.
5. This design uses SSM Run Command serially with local rollback. It is not CodeDeploy, and it is not a transactional blue/green deployment. Two ASG instances and ALB health checks reduce but do not eliminate deployment risk.
6. The GitHub repository should be private before enabling deployment. Do not put AWS access keys or the AWS root credentials in GitHub.
7. The account-level IAM OIDC provider and the ECR repository are created/reused as specified. The ECR repository is an existing resource and is not recreated.

## 0. Prerequisites

- AWS CLI authenticated locally to the account that owns ECR `devops-ec2-hello-world`.
- Terraform >= 1.10 (the reported local version 1.17.1 is sufficient).
- GitHub repository `prayasjat/devops-ec2-project` on branch `main`.
- Existing ECR image v3 digest shown in `infra/terraform.tfvars.example`.
- For HTTPS: a registered DNS domain and a Route 53 public hosted zone for it.

The GitHub OIDC subject is pinned to the immutable repository/owner IDs returned by GitHub:

`repo:prayasjat@215667995/devops-ec2-project@1439686976:ref:refs/heads/main`

## 1. Apply the remote-state bootstrap

The bootstrap stack creates an encrypted, versioned, public-access-blocked S3 bucket. It uses local state only for this one initial bucket.

From the project root:

```bash
export AWS_PROFILE=devops-lab
cd infra/bootstrap
terraform init
terraform plan
terraform apply
```

Confirm the output bucket name matches the bucket configured in `infra/backend.tf`:

`devops-ec2-project-tfstate-632843870789-ap-south-1`

If the bucket name is already owned by another account, change both `infra/bootstrap/main.tf`'s naming scheme and `infra/backend.tf` to a unique name before applying the main stack.

## 2. Initialize and apply the main infrastructure

Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and set domain/hosted-zone values if available.

```bash
cd ../
terraform init -migrate-state
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Review the plan carefully. It creates VPC networking, NAT gateways, ALB, two EC2 instances, IAM roles, SSM parameter, ECR OIDC trust role, and CloudWatch log group/alarm. Do not apply if the plan proposes deleting resources you need.

After apply, capture the `github_actions_role_arn` output.

## 3. Configure GitHub

1. Set repository visibility to **Private**.
2. Open Settings → Secrets and variables → Actions → Variables.
3. Create repository variable `AWS_DEPLOY_ROLE_ARN` with the exact `github_actions_role_arn` Terraform output.
4. Commit and push `.github/workflows/ci-cd.yml` to `main`.
5. The `ci` job runs on pushes and PRs. The publish/deploy job runs only for pushes to `main`.

The workflow tags an image with `${GITHUB_SHA}-${GITHUB_RUN_ATTEMPT}` so immutable ECR tags don't collide when a workflow is rerun. It then queries the resulting digest and deploys by digest.

## 4. Deployment behavior

The main workflow:

1. Runs unit tests and a Docker build in CI.
2. Assumes the narrowly scoped GitHub OIDC role only on `main` pushes.
3. Builds and pushes a unique image tag to ECR.
4. Resolves the ECR digest and writes the digest URI to SSM Parameter Store.
5. Finds running instances tagged `Application=devops-ec2-project`.
6. Sends `AWS-RunShellScript` to one instance at a time, invoking `/usr/local/bin/deploy-app`.
7. The instance pulls the digest, starts Docker, and verifies `/health`.
8. If any instance deployment fails, the workflow restores the previous Parameter Store image URI and redeploys it across the instances.
9. It waits for at least two ALB targets to report healthy.

The instance bootstrap script installs Docker/AWS CLI, enables SSM Agent, installs the deployment script, and starts the known-good initial ECR digest. Application stdout/stderr uses Docker's `awslogs` driver and the instance role's scoped CloudWatch Logs permissions.

## 5. HTTPS setup

When a public Route 53 hosted zone and domain are available, set `domain_name` and `route53_zone_id` in `terraform.tfvars` before `terraform apply`. Terraform requests an ACM DNS-validated certificate, creates validation records, attaches the certificate to the ALB HTTPS listener, and changes the port-80 listener to redirect to 443.

If these values are empty, the stack intentionally exposes HTTP only. Do not claim HTTPS is completed until `https_enabled=true`, DNS resolves to the ALB, and an HTTPS request succeeds.

## 6. Validation checklist

- GitHub Actions CI job green (tests + Docker build).
- Publish/deploy job assumes OIDC role (no stored AWS access keys).
- ECR has the new immutable commit/run-attempt tag and matching digest.
- SSM managed instances show Online.
- Both EC2 instances are InService and ALB targets are healthy.
- `https_enabled` is true before claiming HTTPS.
- Application log streams appear in `/devops-ec2-project/application`.
- Exercise a deliberately bad image only in a disposable test environment to validate the rollback path.

## 7. Cost cleanup

When the lab is not in use, remove the main stack first:

```bash
cd infra
terraform destroy
```

Then optionally remove the backend bucket only after you have safely exported/backed up the state and deliberately removed its `prevent_destroy` protection. NAT gateways, EC2 and ALB are the main continuous cost drivers.
