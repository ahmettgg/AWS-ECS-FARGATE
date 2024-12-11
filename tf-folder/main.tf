provider "aws" {
  region = "us-east-1"
}

# VPC
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "5.13.0"

#   name = "my-vpc"
#   cidr = "10.0.0.0/16"

#   azs             = ["us-east-1a", "us-east-1b"]
#   public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
#   private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

#   enable_nat_gateway = true
#   single_nat_gateway = true
# }

# Security Groups
# resource "aws_security_group" "ecs_sg" {
#   name        = "ecs-sg"
#   description = "Allow traffic to ECS tasks"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }
#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }
 
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "alb_sg" {
#   name        = "alb-sg"
#   description = "Allow inbound traffic to ALB"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # veya spesifik CIDR blokları
#   }
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # veya spesifik CIDR blokları
#   }
  
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# Load Balancer
resource "aws_lb" "ecs-alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

}

# Data source to pull existing ACM certificate
data "aws_acm_certificate" "existing_cert" {
  domain   = "ahmetdevops.click" # Domain covered by the certificate
  statuses = ["ISSUED"]          # Only get the successful certificate

  # Optional: To get the latest one if there is more than one
  most_recent = true
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ecs-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.existing_cert.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    # type             = "forward"
    # target_group_arn = aws_lb_target_group.nginx_tg.id
  }
}
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}
# Nginx için yönlendirme
resource "aws_lb_listener_rule" "nginx_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }
  condition {
    host_header {
      values = ["nginx.ahmetdevops.click"]
    }
  }
  
  }



# Apache için yönlendirme
resource "aws_lb_listener_rule" "apache_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apache_tg.arn
  }
  condition {
    host_header {
      values = ["apache.ahmetdevops.click"]
    }
  }
  
  }

# Wordpress için yönlendirme
resource "aws_lb_listener_rule" "wordpress_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
  condition {
    host_header {
      values = ["wordpress.ahmetdevops.click"]
    }
  }
  
  }


# resource "aws_lb_listener" "lb_listener" {
#   load_balancer_arn = aws_lb.ecs-alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.nginx_tg.id
#   }
# }

# Load Balancer Target Group for Nginx

resource "aws_lb_target_group" "nginx_tg" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id


  target_type = "ip" # Fargate için ip tipi kullanılır

  health_check {
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

}

resource "aws_lb_target_group" "apache_tg" {
  name     = "apache-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id


  target_type = "ip" # Fargate için ip tipi kullanılır

  health_check {
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

}
resource "aws_lb_target_group" "wordpress_tg" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id


  target_type = "ip" # Fargate için ip tipi kullanılır

  health_check {
    interval            = 30
    path                = "/wp-admin/setup-config.php"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

}

# IAM Role for Fargate Tasks
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecs-task-execution-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }
# resource "aws_iam_role_policy_attachment" "ecs_task_cloud_watch_logs" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
# }

# resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# resource "aws_iam_role" "ecs_task_role" {
#   name = "ecs-task-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # Örnek politika, ihtiyaca göre değiştirebilirsiniz
# }

# # ECS Cluster
# resource "aws_ecs_cluster" "main" {
#   name = "ecs-cluster"
# }

# Task Definitions
# resource "aws_ecs_task_definition" "nginx_task" {
#   family                   = "nginx-task"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "4096"
#   memory                   = "8192"

#   container_definitions = jsonencode([
#     {
#       name      = "nginx-container"
#       image     = "nginx:latest"
#       cpu       = 1024
#       memory    = 2048
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80,
#           protocol      = "tcp"
#         }
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = "/ecs/nginx-task"
#           "awslogs-region"        = "us-east-1"
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }
#     }
#   ])
# }
# resource "aws_ecs_task_definition" "apache_task" {
#   family                   = "apache-task"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "4096"
#   memory                   = "8192"

#   container_definitions = jsonencode([
#     {
#       name      = "apache-container"
#       image     = "httpd:latest"
#       cpu       = 1024
#       memory    = 2048
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80,
#           protocol      = "tcp"
#         }
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = "/ecs/apache-task"
#           "awslogs-region"        = "us-east-1"
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }
#     }
#   ])
# }

# resource "aws_ecs_task_definition" "wordpress_task" {
#   family                   = "wordpress-task"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "4096"
#   memory                   = "8192"

#   container_definitions = jsonencode([
#     {
#       name      = "wordpress-container"
#       image     = "wordpress:latest"
#       cpu       = 1024
#       memory    = 2048
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80,
#           protocol      = "tcp"
#         }
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = "/ecs/wordpress-task"
#           "awslogs-region"        = "us-east-1"
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }
#     }
#   ])
# }
# ECS Service
# resource "aws_ecs_service" "nginx_service" {
#   name                               = "nginx-service"
#   cluster                            = aws_ecs_cluster.main.id
#   task_definition                    = aws_ecs_task_definition.nginx_task.arn
#   desired_count                      = 1
#   scheduling_strategy                = "REPLICA"
#   launch_type                        = "FARGATE"
#   deployment_minimum_healthy_percent = 100
#   deployment_maximum_percent         = 200
#   depends_on                         = [aws_lb_listener_rule.wordpress_rule, aws_lb_listener_rule.apache_rule, aws_lb_listener_rule.nginx_rule, aws_lb_listener.https, aws_lb_listener.http, aws_iam_role.ecs_task_execution_role, aws_iam_role.ecs_task_role]

#   network_configuration {
#     subnets          = module.vpc.public_subnets
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.nginx_tg.arn
#     container_name   = "nginx-container"
#     container_port   = 80
#   }
#   force_new_deployment = true
# }

# resource "aws_ecs_service" "apache_service" {
#   name                               = "apache-service"
#   cluster                            = aws_ecs_cluster.main.id
#   task_definition                    = aws_ecs_task_definition.apache_task.arn
#   desired_count                      = 1
#   scheduling_strategy                = "REPLICA"
#   launch_type                        = "FARGATE"
#   deployment_minimum_healthy_percent = 100
#   deployment_maximum_percent         = 200
#   depends_on                         = [aws_lb_listener_rule.wordpress_rule, aws_lb_listener_rule.apache_rule, aws_lb_listener_rule.nginx_rule, aws_lb_listener.https, aws_lb_listener.http, aws_iam_role.ecs_task_execution_role, aws_iam_role.ecs_task_role]

#   network_configuration {
#     subnets          = module.vpc.public_subnets
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.apache_tg.arn
#     container_name   = "apache-container"
#     container_port   = 80
#   }
#   force_new_deployment = true
# }

# resource "aws_ecs_service" "wordpress_service" {
#   name                               = "wordpress-service"
#   cluster                            = aws_ecs_cluster.main.id
#   task_definition                    = aws_ecs_task_definition.wordpress_task.arn
#   desired_count                      = 1
#   scheduling_strategy                = "REPLICA"
#   launch_type                        = "FARGATE"
#   deployment_minimum_healthy_percent = 100
#   deployment_maximum_percent         = 200
#   depends_on                         = [aws_lb_listener_rule.wordpress_rule, aws_lb_listener_rule.apache_rule, aws_lb_listener_rule.nginx_rule, aws_lb_listener.https, aws_lb_listener.http, aws_iam_role.ecs_task_execution_role, aws_iam_role.ecs_task_role]

#   network_configuration {
#     subnets          = module.vpc.public_subnets
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.wordpress_tg.arn
#     container_name   = "wordpress-container"
#     container_port   = 80
#   }
#   force_new_deployment = true
# }
# Eğer Hosted Zone zaten mevcutsa data bloğu ile çekebilirsiniz
data "aws_route53_zone" "selected" {
  name = "ahmetdevops.click"
}

# Route 53 Alias kaydı ile Load Balancer DNS'ini domain'e bağlama
resource "aws_route53_record" "nginx_lb_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id # Mevcut Hosted Zone ID
  name    = "nginx.ahmetdevops.click"              # İstediğiniz domain ya da alt domain
  type    = "A"

  alias {
    name                   = aws_lb.ecs-alb.dns_name # Load Balancer DNS adı
    zone_id                = aws_lb.ecs-alb.zone_id  # Load Balancer Hosted Zone ID'si
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "apache_lb_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id # Mevcut Hosted Zone ID
  name    = "apache.ahmetdevops.click"              # İstediğiniz domain ya da alt domain
  type    = "A"

  alias {
    name                   = aws_lb.ecs-alb.dns_name # Load Balancer DNS adı
    zone_id                = aws_lb.ecs-alb.zone_id  # Load Balancer Hosted Zone ID'si
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "wordpress_lb_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id # Mevcut Hosted Zone ID
  name    = "wordpress.ahmetdevops.click"              # İstediğiniz domain ya da alt domain
  type    = "A"

  alias {
    name                   = aws_lb.ecs-alb.dns_name # Load Balancer DNS adı
    zone_id                = aws_lb.ecs-alb.zone_id  # Load Balancer Hosted Zone ID'si
    evaluate_target_health = false
  }
}