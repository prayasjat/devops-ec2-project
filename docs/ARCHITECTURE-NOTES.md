# Architecture notes

- CI is test + image build. CD publishes the immutable ECR image and uses SSM Run Command for serial EC2 rollout.
- The EC2 Auto Scaling Group is multi-AZ; ASG restores host capacity on instance failures. Application releases are rolled out one instance at a time through SSM.
- A failed instance-local health check attempts to restore the previous Docker image. A pipeline-level failure restores the prior SSM parameter value and rolls back all instances.
- EC2 instances are in private subnets. ALB is internet-facing in two public subnets. NAT Gateway egress is required for package installation, ECR and SSM traffic in this implementation.
- NAT per AZ is enabled by default for AZ-resilient egress, but it is a material recurring cost. A single-NAT mode is configurable and has an egress AZ dependency.
- HTTPS is conditional on a registered domain and a Route 53 public hosted zone. An ACM certificate must match the hostname used by browsers.
- This is a strong hands-on architecture, but it should not be labelled production-certified until load/performance tests, security scanning, disaster recovery, access governance, cost controls, and rollback tests have been completed.
