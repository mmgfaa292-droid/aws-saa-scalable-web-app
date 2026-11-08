output "app_url" {
  description = "Public entry point (CloudFront)"
  value       = local.dns ? "https://${local.app_fqdn}" : "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager secret holding the RDS master credentials"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "session_manager_hint" {
  value = "aws ssm start-session --target <instance-id> --region ${var.region}"
}
