resource "aws_ecs_cluster" "paperqa_cluster" {
  name = "paperqa-cluster"
}

resource "aws_ecs_task_definition" "paperqa_task_definition" {
  family                   = "paperqa-task"
  memory                   = 1024
  cpu                      = 512
  container_definitions    = jsonencode([
    {
      name             = "paperqa",
      image            = "${aws_ecr_repository.paperqa.repository_url}:latest",
      cpu              = 0,
      portMappings     = [
        {
          name          = "paperqa-8501-tcp",
          containerPort = 8501,
          hostPort      = 8501,
          protocol      = "tcp",
          appProtocol   = "http"
        }
      ],
      essential        = true,
      secrets          = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = data.aws_secretsmanager_secret.openai.arn
        }
      ],
      mountPoints      = [],
      volumesFrom      = [],
      logConfiguration = {
        "logDriver" = "awslogs",
        "options"   = {
          "awslogs-group"         = aws_cloudwatch_log_group.paperqa_log_group.name,
          "awslogs-region"        = var.region,
          "awslogs-stream-prefix" = "/ecs"
        }
      }
    }
  ]
  )
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  task_role_arn            = aws_iam_role.paperqa_role.arn
  execution_role_arn       = aws_iam_role.paperqa_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}

data "aws_ecs_container_definition" "paperqa_container" {
  task_definition = aws_ecs_task_definition.paperqa_task_definition.id
  container_name  = "paperqa"
}

resource "aws_ecs_service" "paperqa_service" {
  name            = "paperqa-service"
  cluster         = aws_ecs_cluster.paperqa_cluster.id
  task_definition = aws_ecs_task_definition.paperqa_task_definition.arn
  desired_count   = 1
  depends_on      = [aws_lb.paperqa_lb, aws_lb_listener.paperqa_lb_listener]
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 1
  }
  network_configuration {
    assign_public_ip = true
    subnets          = [
      aws_subnet.paperqa_subnet_a.id,
      aws_subnet.paperqa_subnet_b.id
    ]
    security_groups  = [
      aws_security_group.paperqa_sq.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.paperqa_target_group.arn
    container_name   = data.aws_ecs_container_definition.paperqa_container.container_name
    container_port   = 8501
  }
}