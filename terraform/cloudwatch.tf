resource "aws_cloudwatch_log_group" "paperqa_log_group" {
  name              = "/ecs/paperqa"
  retention_in_days = 7
}
