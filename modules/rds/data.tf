data "aws_ssm_parameter" "username" {
  name = "dev.rds.username"
}

data "aws_ssm_parameter" "password" {
  name = "dev.rds.password"
}