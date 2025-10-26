# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.app_name}-logs"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs.name
      }
    }
  }

  tags = {
    Name = "${var.app_name}-cluster"
  }
}

# COMMENTED OUT - ALB not supported on this account yet
# resource "aws_lb" "main" {
#   name               = "${var.app_name}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = aws_subnet.public[*].id
#   enable_deletion_protection = false
#   tags = {
#     Name = "${var.app_name}-alb"
#   }
# }

# COMMENTED OUT - Target Group
# resource "aws_lb_target_group" "app" {
#   name        = "${var.app_name}-tg"
#   port        = var.container_port
#   protocol    = "HTTP"
#   vpc_id      = aws_vpc.main.id
#   target_type = "ip"
#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     interval            = 30
#     matcher             = "200"
#     path                = "/health"
#     port                = "traffic-port"
#     protocol            = "HTTP"
#     timeout             = 5
#     unhealthy_threshold = 2
#   }
#   tags = {
#     Name = "${var.app_name}-tg"
#   }
# }

# COMMENTED OUT - ALB Listener
# resource "aws_lb_listener" "app" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "80"
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }
