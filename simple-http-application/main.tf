terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }
}


provider "aws" {
        region = "eu-north-1"
        profile = "terraform"
    }



resource "aws_security_group" "name" {

  name = "lb sg"
  description = "for ALB"
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]

  }
  
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
  egress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }



}

resource "aws_lb" "name" {
  load_balancer_type = "application"
  internal = false
  security_groups = [ aws_security_group.name.id ]

  subnets = [ "subnet-05b50b5726a7b72ef","subnet-0b50c8c7ccfd60ff3" ]

}

resource "aws_lb_listener" "name" {
  
  load_balancer_arn = aws_lb.name.arn
  port = 80

  default_action {

    type = "forward"
    target_group_arn = aws_lb_target_group.name.arn

  }
}


resource "aws_lb_target_group" "name" {
  
  port = 5000
  protocol = "HTTP"
  vpc_id = data.aws_vpc.name.id

}

resource "aws_autoscaling_policy" "policy" {

  name = "policy"
  autoscaling_group_name = aws_autoscaling_group.autoscaler-for-flask.name
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  
}

resource "aws_cloudwatch_metric_alarm" "scaling_alarm" {

  alarm_name = "alarm to scale up instances"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  period = 60
  namespace = "AWS/ApplicationELB"
  metric_name = "ActiveConnectionCount"
  statistic = "Sum"
  threshold = 5
  dimensions = {
    LoadBalancer = aws_lb.name.name
  }
  
  alarm_actions = [aws_autoscaling_policy.policy.arn]

}


resource "aws_launch_template" "launch-template-for-flask" {

  name = "launch-template-for-flask"
  image_id = "ami-02a0945ba27a488b7"
  user_data = base64encode(file("script.sh"))
  instance_type = "t3.micro"
  security_group_names = [ data.aws_security_group.to_ssh.name ]

}

resource "aws_autoscaling_group" "autoscaler-for-flask" {
  
  min_size = 1
  max_size = 3
  availability_zones = [ "eu-north-1a" ]
  target_group_arns = [ aws_lb_target_group.name.arn ]

  lifecycle {
    create_before_destroy = true
  }

  launch_template {

    id = aws_launch_template.launch-template-for-flask.id
    
  }
}

