provider "aws" {
  region = "us-east-1"
}


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