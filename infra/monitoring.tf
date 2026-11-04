# Operational visibility, notifications, CPU scaling, and cost guardrails.

# AWS Budgets API endpoints are available in us-east-1, us-west-2 and ca-central-1.
provider "aws" {
  alias  = "billing"
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "host" {
  name              = "/${var.app_name}/application-host"
  retention_in_days = var.log_retention_days
  tags              = { Application = var.app_name, Component = "host" }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "${var.app_name}-operations"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "EC2 Auto Scaling Group CPU"
          view    = "timeSeries", region = var.aws_region, period = 300, stat = "Average"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.app.name]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "Host memory utilization"
          view    = "timeSeries", region = var.aws_region, period = 300, stat = "Average"
          metrics = [["CWAgent", "mem_used_percent", "AutoScalingGroupName", aws_autoscaling_group.app.name]]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title = "Application request count and target 5xx"
          view  = "timeSeries", region = var.aws_region, period = 60, stat = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app.arn_suffix, "TargetGroup", aws_lb_target_group.app.arn_suffix]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title = "Healthy and unhealthy ALB targets"
          view  = "timeSeries", region = var.aws_region, period = 60, stat = "Average"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", aws_lb.app.arn_suffix, "TargetGroup", aws_lb_target_group.app.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", aws_lb.app.arn_suffix, "TargetGroup", aws_lb_target_group.app.arn_suffix]
          ]
        }
      }
    ]
  })
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.app_name}-cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name

  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}

resource "aws_sns_topic" "operations_alerts" {
  name = "${var.app_name}-operations-alerts"
  tags = { Application = var.app_name }
}

resource "aws_sns_topic_subscription" "operations_email" {
  count     = trimspace(var.alert_email) == "" ? 0 : 1
  topic_arn = aws_sns_topic.operations_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${var.app_name}-asg-cpu-high"
  alarm_description   = "Average application Auto Scaling Group CPU is at least 80 percent."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.operations_alerts.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.app_name}-unhealthy-targets"
  alarm_description   = "An ALB application target has remained unhealthy for two periods."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.operations_alerts.arn]
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
}

resource "aws_budgets_budget" "monthly_cost" {
  provider     = aws.billing
  count        = trimspace(var.alert_email) == "" ? 0 : 1
  name         = "${var.app_name}-monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.alert_email]
  }
}
