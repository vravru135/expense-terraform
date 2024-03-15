/*data "aws_ami" "ami" {
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
  owners      = ["290654222953"]
}*/


data "aws_ami" "ami" {
  most_recent = true
  name_regex  = "golden-ami"
  owners      = ["290654222953"]
}