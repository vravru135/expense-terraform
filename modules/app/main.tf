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

  ingress {
    description = "PROMETHEUS"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.prometheus_cidrs
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
  tags                   = merge(var.tags, { Name = "${var.env}-${var.component}" })

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    role_name = var.component
    env       = var.env
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 10
      encrypted             = true
      kms_key_id            = var.kms
      delete_on_termination = true
    }
  }

}

resource "aws_autoscaling_group" "main" {
  name                = "${var.env}-${var.component}"
  desired_capacity    = var.instance_count
  max_size            = var.instance_count + 5
  min_size            = var.instance_count
  vpc_zone_identifier = var.subnets
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-${var.component}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Monitor"
    value               = "true"
    propagate_at_launch = true
  }

}

resource "aws_lb_target_group" "main" {
  name                 = "${var.env}-${var.component}"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 10

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    matcher             = 200
    path                = "/health"
    timeout             = 2
  }
}


resource "aws_iam_role" "main" {
  name = "${var.env}-${var.component}"
  tags = merge(var.tags, { Name = "${var.env}-${var.component}" })

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "SSM-Read-Access"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "GetResources",
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameterHistory",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          "Resource" : [
            "arn:aws:ssm:us-east-1:633788536644:parameter/${var.env}.${var.component}.*",
            "arn:aws:ssm:us-east-1:633788536644:parameter/newrelic.licence_key",
            "arn:aws:ssm:us-east-1:633788536644:parameter/${var.env}.rds.*",
            "arn:aws:ssm:us-east-1:633788536644:parameter/grafana.api_key",
            "arn:aws:ssm:us-east-1:633788536644:parameter/jenkins.*",
            "arn:aws:ssm:us-east-1:633788536644:parameter/artifactory.*"
          ]
        },
        {
          "Sid" : "ListResources",
          "Effect" : "Allow",
          "Action" : "ssm:DescribeParameters",
          "Resource" : "*"
        },
        {
          "Sid" : "S3UploadForPrometheusAlerts",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject",
            "s3:DeleteObjectVersion",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "arn:aws:s3:::d76-prometheus-alert-rules/*",
            "arn:aws:s3:::d76-prometheus-alert-rules"
          ]
        }
      ]
    })
  }

}

resource "aws_iam_instance_profile" "main" {
  name = "${var.env}-${var.component}"
  role = aws_iam_role.main.name
}






