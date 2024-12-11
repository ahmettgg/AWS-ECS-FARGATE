# ECS Service
resource "aws_ecs_service" "nginx_service" {
  name                               = "nginx-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.nginx_task.arn
  desired_count                      = 1
  scheduling_strategy                = "REPLICA"
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  depends_on                         = [aws_lb_listener_rule.wordpress_rule, aws_lb_listener_rule.apache_rule, aws_lb_listener_rule.nginx_rule, aws_lb_listener.https, aws_lb_listener.http, aws_iam_role.ecs_task_execution_role, aws_iam_role.ecs_task_role]

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_tg.arn
    container_name   = "nginx-container"
    container_port   = 80
  }
  force_new_deployment = true
}

resource "aws_ecs_service" "apache_service" {
  name                               = "apache-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.apache_task.arn
  desired_count                      = 1
  scheduling_strategy                = "REPLICA"
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  depends_on                         = [aws_lb_listener_rule.wordpress_rule, aws_lb_listener_rule.apache_rule, aws_lb_listener_rule.nginx_rule, aws_lb_listener.https, aws_lb_listener.http, aws_iam_role.ecs_task_execution_role, aws_iam_role.ecs_task_role]

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.apache_tg.arn
    container_name   = "apache-container"
    container_port   = 80
  }
  force_new_deployment = true
}

resource "aws_ecs_service" "wordpress_service" {
  name                               = "wordpress-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.wordpress_task.arn
  desired_count                      = 1
  scheduling_strategy                = "REPLICA"
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  depends_on                         = [aws_lb_listener_rule.wordpress_rule, aws_lb_listener_rule.apache_rule, aws_lb_listener_rule.nginx_rule, aws_lb_listener.https, aws_lb_listener.http, aws_iam_role.ecs_task_execution_role, aws_iam_role.ecs_task_role]

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
    container_name   = "wordpress-container"
    container_port   = 80
  }
  force_new_deployment = true
}