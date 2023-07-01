data "aws_route53_zone" "paperqa_hosted_zone" {
  name = var.paperqa_hosted_zone
}

resource "aws_route53_record" "paperqa_domain" {
  zone_id = data.aws_route53_zone.paperqa_hosted_zone.zone_id
  name    = var.paperqa_alias
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_lb.paperqa_lb.dns_name
    zone_id                = aws_lb.paperqa_lb.zone_id
  }
}

data "aws_acm_certificate" "paperqa_cert" {
  domain = aws_route53_record.paperqa_domain.name
}