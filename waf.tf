# Create CloudWatch Log Group for WAF logging
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "/aws/waf/global_web_acl"
  retention_in_days = 14 # Retain logs for 14 days (customize based on need)
}

# Create the WAF Web ACL
resource "aws_wafv2_web_acl" "global_web_acl" {
  name        = "global-web-acl"
  description = "A global Web ACL with logging and security rules"
  scope       = "REGIONAL" # Use 'CLOUDFRONT' for CloudFront

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "global-web-acl"
    sampled_requests_enabled   = true
  }

  # Rate limiting rule to prevent DDoS-style attacks
  rule {
    name     = "limit-ip-rate"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000 # Allow only 2000 requests per IP within 5 minutes
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-ip"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule Group for common threats (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Custom rule to block Log4j2 exploit attempts
  rule {
    name     = "block-log4j2-exploit"
    priority = 3

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string = "{jndi:"
        field_to_match {
          all_query_arguments {}
        }
        text_transformation {
          priority = 1
          type     = "NONE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-log4j2-exploit"
      sampled_requests_enabled   = true
    }
  }
}
