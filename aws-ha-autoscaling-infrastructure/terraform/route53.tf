# Optional: friendly domain name (app.example.com) pointing to the ALB.
# Only created when var.domain_name is set and the hosted zone already exists.

data "aws_route53_zone" "main" {
  count = var.domain_name == "" ? 0 : 1
  name  = var.domain_name
}

resource "aws_route53_record" "app" {
  count   = var.domain_name == "" ? 0 : 1
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  # Alias record: free, and follows the ALB if its IPs change
  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
