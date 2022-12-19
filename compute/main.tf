# -- compute/main.tf --

data "aws_ami" "web_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "random_id" "node_id" {
  byte_length = 2
  count       = var.instance_count
}

resource "aws_instance" "bastion-instance" {
  count         = 1
  instance_type = var.instance_type
  ami           = data.aws_ami.web_ami.id
  tags = {
    Name = "bastion-instance-${random_id.node_id[count.index].dec}"
  }
  key_name               = "LabKey"
  vpc_security_group_ids = [var.public_security_group]
  subnet_id              = var.public_subnets[count.index]
  lifecycle {
    ignore_changes = [tags]
  }
  root_block_device {
    volume_size = var.volume_size
  }
}

#AWS Load Balancing Target Group
resource "aws_lb_target_group" "web_alb_target_group" {
  name        = "web-alb"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  tags = {
    Name = "web-alb-target-group"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "web_alb" {
  name                       = "web-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.public_security_group]
  subnets                    = var.public_subnets
  enable_deletion_protection = false
  tags = {
    Name = "web-alb"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  protocol          = "HTTP"
  port              = "80"
  depends_on        = [aws_lb_target_group.web_alb_target_group, aws_lb.web_alb]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_alb_target_group.arn
  }
}

# Creating the autoscaling launch configuration that contains AWS EC2 instance details
resource "aws_launch_configuration" "web_autoscale_configuration" {
  name = "web-configuration"

  image_id        = data.aws_ami.web_ami.id
  instance_type   = var.instance_type
  security_groups = [var.web_security_group]
  user_data       = file("${path.module}/nginxbootstrap.txt")
  lifecycle {
    create_before_destroy = true
  }
  key_name = "LabKey"
}

# Creating the autoscaling group
resource "aws_autoscaling_group" "web_autoscaling_group" {
  name                      = "web-autoscale-group"
  min_size                  = 2
  max_size                  = 5
  health_check_grace_period = 45
  health_check_type         = "ELB"
  force_delete              = true
  termination_policies      = ["Default"]
  target_group_arns         = [aws_lb_target_group.web_alb_target_group.arn]

  # Defining the Subnets in which AWS EC2 instance will be launched
  #This argument takes a list of subnets
  vpc_zone_identifier = var.web_subnets
  tag {
    key                 = "Name"
    value               = "web-autoscale-instance"
    propagate_at_launch = true
  }
  launch_configuration = aws_launch_configuration.web_autoscale_configuration.name
  depends_on           = [aws_launch_configuration.web_autoscale_configuration]
  lifecycle {
    create_before_destroy = true
  }
}