resource "aws_security_group" "paperqa_sq" {
  name        = "paperqa-sg"
  description = "Allow inbound traffic on HTTPS port 443"
  vpc_id      = aws_vpc.paperqa_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#

resource "aws_lb" "paperqa_lb" {
  name               = "paperqa-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.paperqa_sq.id]
  subnets            = [
    aws_subnet.paperqa_subnet_a.id,
    aws_subnet.paperqa_subnet_b.id
  ]
}

resource "aws_lb_listener" "paperqa_lb_listener" {
  load_balancer_arn = aws_lb.paperqa_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.paperqa_cert.arn
  //  First, the listener will direct the traffic to Cognito for authentication
  default_action {
    type  = "authenticate-cognito"
    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.paperqa_user_pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.paperqa_user_pool_client.id
      user_pool_domain    = aws_cognito_user_pool_domain.paperqa_user_pool_domain.domain
    }
    order = 1
  }
  //  After successful authentication, traffic will be forwarded to
  //  the target group, i.e. the application
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.paperqa_target_group.arn
    order            = 2
  }
}

resource "aws_lb_target_group" "paperqa_target_group" {
  name        = "paperqa-target-group"
  port        = 8501
  protocol    = "HTTP"
  vpc_id      = aws_vpc.paperqa_vpc.id
  target_type = "ip"

  //  The health check path for streamlit applications is /healthz.
  //  It is important to add 304 to the matcher, because streamlit
  //  will return the 200 status only the first time and every
  //  subsequent call returns 304 (Not Modified)
  health_check {
    interval            = 30
    path                = "/healthz"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200,304"
  }

}
