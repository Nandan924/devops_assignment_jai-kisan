provider "aws" {
    region = "us-east-1" 
}



# This is Assignment 2

resource "aws_vpc" "task2_vpc" {
  cidr_block = "10.0.0.0/16"

    tags = {
    Name = "Task2-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.task2_vpc.id
  tags = {
    Name = "MyInternetGateway"
  }
  
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.task2_vpc.id
  cidr_block = "10.0.1.0/24" 
  availability_zone = "us-east-1a" 
   tags = {
    Name = "Subnet-1a"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.task2_vpc.id
  cidr_block = "10.0.2.0/24" 
  availability_zone = "us-east-1b"
   tags = {
    Name = "Subnet-1b"
  } 
}

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.task2_vpc.id

tags = {
    Name = "RouteTable"
  }
}

resource "aws_route" "my_route" {
  route_table_id         = aws_route_table.routetable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "subnet1_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetable.id
}
resource "aws_route_table_association" "subnet2_association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable.id
}


resource "aws_lb" "alb" {
  name               = "appliction-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id] 
  security_groups = [aws_security_group.sg.id]
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.task2_vpc.id
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_ecs_task_definition" "taskdefinition" {
  family                   = "task2-td"
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = <<DEFINITION
  [
    {
      "name": "ecs-container",
      "image": "httpd:2.4", 
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/cw-task",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  DEFINITION
}

resource "aws_ecs_service" "ecs" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecscluster.id
  task_definition = aws_ecs_task_definition.taskdefinition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet1.id , aws_subnet.subnet2.id] 
    security_groups = [aws_security_group.sg.id] 
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    container_name   = "ecs-container"
    container_port   = 80
  }
}

resource "aws_ecs_cluster" "ecscluster" {
  name = "ecs-cluster"
}

resource "aws_security_group" "sg" {
  name        = "security-group"
  description = "security group for ECS service"
  vpc_id      = aws_vpc.task2_vpc.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_cloudwatch_log_group" "cw_loggroup" {
  name              = "/ecs/cw-task"
  retention_in_days = 7
}