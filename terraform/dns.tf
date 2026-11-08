# Everything here is created only when var.domain_name is set.

data "aws_route53_zone" "this" {
  count        = local.dns ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# ---- ACM cert for the ALB (same region as ALB) ----
resource "aws_acm_certificate" "alb" {
  count             = local.dns ? 1 : 0
  domain_name       = local.alb_fqdn
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}

# ---- ACM cert for CloudFront (must be us-east-1) ----
resource "aws_acm_certificate" "cloudfront" {
  count             = local.dns ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = local.app_fqdn
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "alb_validation" {
  for_each = local.dns ? {
    for o in aws_acm_certificate.alb[0].domain_validation_options : o.domain_name => o
  } : {}
  zone_id         = data.aws_route53_zone.this[0].zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_route53_record" "cf_validation" {
  for_each = local.dns ? {
    for o in aws_acm_certificate.cloudfront[0].domain_validation_options : o.domain_name => o
  } : {}
  zone_id         = data.aws_route53_zone.this[0].zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  count                   = local.dns ? 1 : 0
  certificate_arn         = aws_acm_certificate.alb[0].arn
  validation_record_fqdns = [for r in aws_route53_record.alb_validation : r.fqdn]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  count                   = local.dns ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cf_validation : r.fqdn]
}

# ---- Alias record -> ALB (origin), with health check ----
resource "aws_route53_health_check" "alb" {
  count             = local.dns ? 1 : 0
  fqdn              = local.alb_fqdn
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  tags              = { Name = "${var.project_name}-alb-health" }
  depends_on        = [aws_route53_record.alb]
}

resource "aws_route53_record" "alb" {
  count   = local.dns ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = local.alb_fqdn
  type    = "A"
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

# ---- Public entry point -> CloudFront ----
resource "aws_route53_record" "app" {
  count   = local.dns ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = local.app_fqdn
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
