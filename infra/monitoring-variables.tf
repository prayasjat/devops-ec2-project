variable "alert_email" {
  type        = string
  default     = ""
  description = "Email for SNS operational alerts and AWS Budget alerts; confirm the SNS subscription."
}

variable "monthly_budget_limit_usd" {
  type        = number
  default     = 25
  description = "Monthly AWS budget limit in USD."
  validation {
    condition     = var.monthly_budget_limit_usd > 0
    error_message = "monthly_budget_limit_usd must be greater than zero."
  }
}
