output "alb_dns_name" {
  description = "Open this in the browser"
  value       = "http://${aws_lb.app.dns_name}"
}

output "app_url" {
  value = var.domain_name == "" ? "http://${aws_lb.app.dns_name}" : "http://${var.subdomain}.${var.domain_name}"
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
