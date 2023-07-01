variable "paperqa_hosted_zone" {
  description = "Name of your hosted zone in Route 53"
  type        = string
  default     = "example-domain.com"
}

variable "paperqa_alias" {
  description = "Alias of your domain under which the app will run"
  type        = string
  default     = "alias.example-domain.com"
}

variable "cognito_reply_to_mail" {
  description = "The mail address to use for replies to the cognito invitation mail"
  type        = string
  default     = "examplemail.com"
}

variable "region" {
  description = "The region to create all resources in"
  type = string
  default = "eu-central-1"
}

variable "aws_profile" {
  description = "Name of your AWS profile"
  type = string
  default = "ExampleCLIProfile"
}