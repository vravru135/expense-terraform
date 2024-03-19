data "aws_ami" "main" {
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
  owners      = ["290654222953"]
}
