## IAM Policies and Roles ##
locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "ecs_service_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role_pd.json

  inline_policy {
    name = "ecs-service"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:Describe*",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "elasticloadbalancing:RegisterTargets",
            "ec2:Describe*",
            "ec2:AuthorizeSecurityGroupIngress"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_role" "ec2_role" {
  name                = "ec2_role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.ec2_role_pd.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]

  inline_policy {
    name = "ecs-service"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ec2:DescribeTags",
            "ecs:CreateCluster",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:UpdateContainerInstancesState",
            "ecs:Submit*"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "dynamo-access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:us-west-2:${local.account_id}:*/*",
            "arn:aws:dynamodb:us-west-2:${local.account_id}:*/*"
          ]
        }
      ]
    })
  }
  
  inline_policy {
    name = "rds-access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
	  Action = [
	    "rds:*",
            "application-autoscaling:DeleteScalingPolicy",
            "application-autoscaling:DeregisterScalableTarget",
            "application-autoscaling:DescribeScalableTargets",
            "application-autoscaling:DescribeScalingActivities",
            "application-autoscaling:DescribeScalingPolicies",
            "application-autoscaling:PutScalingPolicy",
            "application-autoscaling:RegisterScalableTarget",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DeleteAlarms",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeCoipPools",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeLocalGatewayRouteTables",
            "ec2:DescribeLocalGatewayRouteTableVpcAssociations",
            "ec2:DescribeLocalGateways",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcs",
            "ec2:GetCoipPoolUsage",
            "sns:ListSubscriptions",
            "sns:ListTopics",
            "sns:Publish",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents",
            "outposts:GetOutpostInstanceTypes"
	  ]
	  Effect = "Allow",
	  Resource: "*"
        },
	{
            Action: "pi:*",
            Effect: "Allow",
            Resource: "arn:aws:pi:*:*:metrics/rds/*"
        },
	{
            Action: "iam:CreateServiceLinkedRole",
            Effect: "Allow",
            Resource: "*",
            Condition: {
                StringLike: {
                    "iam:AWSServiceName": [
                        "rds.amazonaws.com",
                        "rds.application-autoscaling.amazonaws.com"
                    ]
                }
            }
        },
	{
	    Effect: "Allow",
	    Action: [
                "rds-db:connect"
            ],
            Resource: [
                "arn:aws:rds-db:us-west-2:${local.account_id}:dbuser:*/*"
            ]
	}
         
      ]
    })
  }

  inline_policy {
    name = "ecr-access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetAuthorizationToken"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_role" "autoscaling_role" {
  name               = "autoscaling_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.autoscaling_pd.json

  inline_policy {
    name = "service-autoscaling"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecs:DescribeServices",
            "ecs:UpdateService",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:DeleteAlarms"
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:ecs:us-west-2:${local.account_id}:*/*",
            "arn:aws:cloudwatch:us-west-2:${local.account_id}:*/*"
          ]
        }
      ]
    })
  }
}


# Create a security group for the ALB.
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "ECS security group for the ALB."
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 31000
    to_port   = 61000
    self      = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a CloudWatch log group.
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "ecs-logs"
  retention_in_days = 14
}

# Create an ECS task definition.
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                = "${var.service_name}-ecs-demo-app"
  container_definitions = <<DEFINITION
[
  {
    "name": "demo-app",
    "cpu": 10,
    "image": "${var.ecr_image_url}",
    "essential": true,
    "memory": 300,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "ecs-logs",
        "awslogs-region": "us-west-2",
        "awslogs-stream-prefix": "ecs-demo-app"
      }
    },
    "mountPoints": [
      {
        "containerPath": "/usr/local/apache2/htdocs",
        "sourceVolume": "my-vol"
      }
    ],
    "portMappings": [
      {
        "containerPort": 5000
      }
    ]
  }
]
DEFINITION
  volume {
    name = "my-vol"
  }
}

# Create the Application Load Balancer.
resource "aws_lb" "main" {
  name                       = "ecsalb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ecs_sg.id]
  subnets                    = ["${var.subnet_id}","${var.subnet2_id}"]
  idle_timeout               = 30
  enable_deletion_protection = false
}

# Create the ALB target group.
resource "aws_lb_target_group" "ecs_rest_api_tg" {
  name     = "ecs-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 10
    matcher             = "200"
  }
}

# Create the ALB listener.
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.ecs_rest_api_tg.arn
    type             = "forward"
  }
}

# Create the ECS cluster.
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs_cluster"
}

# Create the ECS service.
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.desired_capacity
  iam_role        = aws_iam_role.ecs_service_role.arn
  depends_on      = [aws_lb_listener.alb_listener]
  load_balancer {
    container_name   = "demo-app"
    container_port   = 5000
    target_group_arn = aws_lb_target_group.ecs_rest_api_tg.arn
  }
}

# Create an EC2 instance profile.
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Create an EC2 Launch Configuration for the ECS cluster.
resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = data.aws_ami.latest_ecs_ami.image_id
  security_groups      = [aws_security_group.ecs_sg.id]
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=ecs_cluster >> /etc/ecs/ecs.config"
}

# Create the ECS autoscaling group.
resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "ecs-asg"
  vpc_zone_identifier  = ["${var.subnet_id}"]
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity = var.desired_capacity
  min_size         = 1
  max_size         = var.maximum_capacity
}

# Create an autoscaling policy.
resource "aws_autoscaling_policy" "ecs_infra_scale_out_policy" {
  name                   = "ecs_infra_scale_out_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

# Create an application autoscaling target.
resource "aws_appautoscaling_target" "ecs_service_scaling_target" {
  max_capacity       = 5
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${var.service_name}"
  role_arn           = aws_iam_role.autoscaling_role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on         = [aws_ecs_service.service]
}

# Create an ECS service CPU target tracking scale out policy.
resource "aws_appautoscaling_policy" "ecs_service_cpu_scale_out_policy" {
  name               = "cpu-target-tracking-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Create an ECS service memory target tracking scale out policy.
resource "aws_appautoscaling_policy" "ecs_service_memory_scale_out_policy" {
  name               = "memory-target-tracking-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Create a CloudWatch alarm for ECS service CPU scale out.
resource "aws_cloudwatch_metric_alarm" "ecs_service_cpu_scale_out_alarm" {
  alarm_name          = "CPU utilization greater than 50%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "Alarm if CPU utilization is greater than 50% of reserved CPU"
  dimensions = {
    "Name"  = "ClusterName"
    "Value" = aws_ecs_cluster.ecs_cluster.name
  }
  alarm_actions = [aws_appautoscaling_policy.ecs_service_cpu_scale_out_policy.arn]
}

# Create a CloudWatch alarm for ECS service CPU scale out.
resource "aws_cloudwatch_metric_alarm" "ecs_infra_cpu_alarm_high" {
  alarm_name          = "CPU utilization greater than 50%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "Alarm if CPU too high or metric disappears indicating instance is down"
  dimensions = {
    "Name"  = "AutoScalingGroupName"
    "Value" = aws_autoscaling_group.ecs_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.ecs_infra_scale_out_policy.arn]
}

