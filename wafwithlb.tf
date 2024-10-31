provider "aws" {
  region = "us-east-1"
}

# Define the WAF Web ACL with Rate-Limiting Rule
resource "aws_wafv2_web_acl" "rate_limit_web_acl" {
  name        = "rate-limit-web-acl"
  description = "Web ACL for existing ALB with rate-limiting rule"
  scope       = "REGIONAL"  # Use 'REGIONAL' for ALB, 'CLOUDFRONT' for CloudFront

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "rate-limit-web-acl"
    sampled_requests_enabled   = true
  }

  # Rate limiting rule to protect against DDoS-style attacks
  rule {
    name     = "rate-limit-ip"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000  # Limit to 2000 requests per IP in 5 minutes
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-ip"
      sampled_requests_enabled   = true
    }
  }
}

# Associate WAF Web ACL with Existing ALB
resource "aws_wafv2_web_acl_association" "alb_association" {
  resource_arn = "arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/alb-name/alb-id"  # Replace with your ALB ARN
  web_acl_arn  = aws_wafv2_web_acl.rate_limit_web_acl.arn
}