# Delivery iteration status — 4 November 2026

## Verified on the current main branch

- GitHub Actions run #3 completed successfully.
- The unit-test and Docker build job passed.
- The publish/deploy job successfully assumed the AWS role through GitHub OIDC.
- A new immutable ECR image was published and deployed to two EC2 instances through SSM.
- The workflow's final ALB health check reported two healthy targets.
- Deployment is serial, uses a local `/health` probe on each EC2 instance, restores the prior local container image on an instance-level health failure, and checks ALB target health after the rollout.

## Added in the hardening branch; not yet merged or applied

- Dependency audit using pip-audit.
- Container vulnerability scanning using Trivy.
- CycloneDX image SBOM generated and uploaded as a workflow artifact.
- Terraform formatting, initialization, validation, and Trivy IaC scanning.
- Weekly Dependabot updates for Python packages and GitHub Actions.
- EC2 CloudWatch Agent installation for host CPU, memory, disk and bootstrap-log telemetry.
- CloudWatch operations dashboard, ALB/ASG alarms and SNS email subscription.
- CPU target-tracking Auto Scaling policy (60% target).
- Monthly AWS cost budget with 80% actual and 100% forecast notification thresholds.

## Required owner actions / remaining validation

1. Change repository visibility to Private in GitHub Settings.
2. Enable branch protection for `main`; require pull requests and the successful CI and security checks. Do not require a check name until its first successful run is visible in GitHub.
3. Configure `alert_email` and `monthly_budget_limit_usd` in `infra/terraform.tfvars`. Confirm the SNS subscription email after apply.
4. Review and apply the Terraform changes in the intended AWS account. The new dashboard, alarms, CloudWatch Agent, budget, SNS topic and target-tracking policy do not exist until Terraform is applied.
5. Upgrade the current serial rollout to explicit ALB target draining and per-instance target re-registration/health verification before claiming fully safe rolling deployment.
6. Run a controlled rollback test using a disposable bad image, then test scale-out/scale-in and instance failure.
7. HTTPS remains blocked until a domain under your control and its public Route 53 hosted zone are available; then configure `domain_name` and `route53_zone_id`, apply Terraform, and verify DNS plus HTTPS.

## Accuracy note

A successful deployment run is evidence of a working deployment path, not proof of every production control. Do not describe resources added only in this branch as deployed or operational until the PR is merged, Terraform is applied, and the resulting AWS resources and notifications are verified.
