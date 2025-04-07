provider "aws" {
  region = "us-west-2"
}

# VPC and networking resources
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "medusa-vpc"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_subnet" "main_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "medusa-subnet-a"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_subnet" "main_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "medusa-subnet-b"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "medusa-igw"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "medusa-public-rt"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.main_b.id
  route_table_id = aws_route_table.public.id
}

# HTTP Load Balancer (required by your container references)
resource "aws_lb" "lb_http" {
  name               = "medusa-lb-http"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.main_a.id, aws_subnet.main_b.id]

  tags = {
    Name = "medusa-lb-http"
    CreatedBy = "nXtCyberNet"
  }
}

# Security Groups
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medusa-sg"
    CreatedBy = "nXtCyberNet"
  }
}

# Load balancer security group
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medusa-lb-sg"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_lb" "app_lb" {
  name               = "medusa-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.main_a.id, aws_subnet.main_b.id]

  tags = {
    Name = "medusa-app-lb"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "medusa-app-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  tags = {
    Name = "medusa-app-tg"
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 9000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_ecs_cluster" "main" {
  name = "medusa"
  
  tags = {
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "medusa-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  
  tags = {
    CreatedBy = "nXtCyberNet"
  }
}

resource "aws_iam_policy" "ecr_access_policy" {
  name        = "ecr-access-policy"
  description = "Policy that allows pulling from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_ecr_policy_attachment" {
  name       = "ecs_ecr_policy_attachment"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = aws_iam_policy.ecr_access_policy.arn
}

resource "aws_iam_policy_attachment" "ecs_task_execution_role_policy" {
  name       = "ecs_task_execution_role_policy"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Variables for ECR repository
variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "123456789012" # Replace with your actual AWS account ID
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        },
      ]
    },
    {
      name      = "postgres"
      image     = "postgres"
      essential = true
      environment = [
        {
          name  = "POSTGRES_PASSWORD"
          value = "mysecretpassword"
        },
        {
          name  = "POSTGRES_USER"
          value = "postgres"
        },
        {
          name  = "POSTGRES_DB"
          value = "medusa"
        },
        {
          name  = "DB_HOST"
          value = "${aws_lb.lb_http.dns_name}"
        },
      ]
      portMappings = [
        {
          containerPort = 5432
          hostPort      = 5432
        },
      ]
    },
    {
      name      = "redis"
      image     = "redis"
      essential = true
      environment = [
        {
          name  = "REDIS_HOST"
          value = "${aws_lb.lb_http.dns_name}"
        },
      ]
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
        },
      ]
    },
    {
      name      = "aws-app"
      image     = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/nothing:latest"
      essential = true
      environment = [
        {
          name  = "POSTGRES_HOST"
          value = "localhost"
        },
        {
          name  = "POSTGRES_PORT"
          value = "5432"
        },
        {
          name  = "POSTGRES_DB"
          value = "medusa"
        },
        {
          name  = "POSTGRES_USER"
          value = "postgres"
        },
        {
          name  = "REDIS_HOST"
          value = "localhost"
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        },
        {
          name  = "APP_PORT"
          value = "9000"
        }
      ]
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
        },
      ]
    }
  ])
  
  tags = {
    CreatedBy = "nXtCyberNet"
  }
}

# Add an ECR image pull data source to ensure always getting the latest image
data "aws_ecr_image" "app_image" {
  repository_name = "nothing"
  image_tag       = "latest"
}

resource "aws_ecs_service" "main" {
  name                = "ecs-service"
  cluster             = aws_ecs_cluster.main.id
  task_definition     = aws_ecs_task_definition.main.arn
  desired_count       = 1
  launch_type         = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.main_a.id, aws_subnet.main_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "aws-app"
    container_port   = 9000
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  deployment_controller {
    type = "ECS"
  }
  
  tags = {
    Name = "medusa-ecs-service"
    CreatedBy = "nXtCyberNet"
  }
}

output "app_load_balancer_dns" {
  value = aws_lb.app_lb.dns_name
  description = "DNS name of the application load balancer"
}

output "http_load_balancer_dns" {
  value = aws_lb.lb_http.dns_name
  description = "DNS name of the HTTP load balancer"
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  value = aws_ecs_service.main.name
}

output "ecr_repository_url" {
  value = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/nothing"
  description = "URL of the ECR repository"
}
