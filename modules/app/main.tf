resource "aws_security_group" "main" {
  name        = "${var.env}-${var.component}"
  description = "${var.env}-${var.component}"
  vpc_id      = var.vpc_id

  ingress {
    description = "APP"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.sg_cidrs
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_cidrs
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "${var.env}-${var.component}" })
}

resource "aws_launch_template" "main" {
  name                   = "${var.env}-${var.component}"
  image_id               = data.aws_ami.ami.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  tags                    = merge(var.tags, { Name = "${var.env}-${var.component}" })
}

resource "aws_autoscaling_group" "main" {
  name                = "${var.env}-${var.component}"
  desired_capacity    = var.instance_count
  max_size            = var.instance_count + 5
  min_size            = var.instance_count
  vpc_zone_identifier = var.subnets


  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
    tag {
      key                 = "Name"
      value               = "${var.env}-${var.component}"
      propagate_at_launch = true
    }
}
