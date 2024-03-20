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
  tags                   = merge(var.tags, { Name = "${var.env}-${var.component}" })
  user_data              = base64encode(templatefile("${path.module}/userdata.sh", {
      role_name = var.component
      env       = var.env
    }))
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

#resource "aws_iam_role" "main" {
 # name = "${var.env}-${var.component}"
  #tags = merge(var.tags, { Name = "${var.env}-${var.component}" })

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
    name = "SSM-read-access"

    policy = jsonencode({
  	"Version": "2012-10-17",
  	"Statement": [
  	  {
  	    "Sid": "Get Resources",
  		"Effect": "Allow",
  		"Action": [
  		   "ssm:GetParameterHistory",
  			"ssm:GetParametersByPath",
  			"ssm:GetParameters",
  			"ssm:GetParameter"
  		  ],
  		  "Resource": "arn:aws:ssm:us-east-1:290654222953:parameter/${var.env}.${var.component}.*"
  		},
  		{
  		"Sid": "List Resources",
  		"Effect": "Allow",
  		"Action": "ssm:DescribeParameters",
  		"Resource": "*"
  	  }
  	]
  })
}

}