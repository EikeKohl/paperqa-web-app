resource "aws_cognito_user_pool" "paperqa_user_pool" {
  name                     = "paperqa-users"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"
  email_configuration {
    reply_to_email_address = var.cognito_reply_to_mail
  }

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  admin_create_user_config {
    invite_message_template {
      email_message = <<-EOT
      Hello,<br><br>

      Welcome to the web application <a href="https://paperqa.kohlmeyer-ai.com">PaperQA</a>.<br>
      Your temporary password is {####} .<br>
      Please login with {username} to create your permanent password.<br><br>

      Best Regards,<br>
      Your Admin
      EOT
      email_subject = "Welcome to PaperQA"
      // Unfortunately, we have to give a sms_message template, although we don't use it
      sms_message   = "Placeholder SMS message {username} {####}"
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
}

resource "aws_cognito_user_pool_client" "paperqa_user_pool_client" {
  name                                 = "paperqa-app"
  user_pool_id                         = aws_cognito_user_pool.paperqa_user_pool.id
  generate_secret                      = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid"]
  //  For the callback_urls, it is important to use your domain, as well as the load balancer,
  //  because of the authentication workflow that will ping both these addresses
  //  (see https://aws.amazon.com/de/blogs/containers/securing-amazon-elastic-container-service-applications-using-application-load-balancer-and-amazon-cognito/)
  callback_urls                        = [
    "https://${aws_route53_record.paperqa_domain.name}/oauth2/idpresponse",
    "https://${aws_lb.paperqa_lb.dns_name}/oauth2/idpresponse",
  ]
  supported_identity_providers         = ["COGNITO"]
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_pool_domain" "paperqa_user_pool_domain" {
  domain       = "paperqa"
  user_pool_id = aws_cognito_user_pool.paperqa_user_pool.id
}
