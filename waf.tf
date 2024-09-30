resource "aws_wafv2_web_acl" "global_web_acl" {
  name        = "global-web-acl"
  description = "A global Web ACL"
  scope       = "REGIONAL" # Use CLOUDFRONT for CloudFront-specific WAF

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "global-web-acl"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "limit-ip-rate"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-ip"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "global-web-acl"
  }
}