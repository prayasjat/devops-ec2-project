output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Set as GitHub Actions repository variable AWS_DEPLOY_ROLE_ARN."
}

output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "ALB DNS name. HTTP works without a custom domain."
}

output "application_url" {
  value       = local.enable_https ? "https://${var.domain_name}" : "http://${aws_lb.app.dns_name}"
  description = "HTTPS is enabled only when domain_name and route53_zone_id are provided."
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.app.name
}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.app.repository_url
}

output "application_log_group" {
  value = aws_cloudwatch_log_group.app.name
}

output "https_enabled" {
  value = local.enable_https
}
