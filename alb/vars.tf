variable "env" {}
variable "type" {}
variable "internal" {}
variable "vpc_id" {}
variable "lb_port" {}
variable "sg_cidrs" {}
variable "tags" {}
variable "subnets" {}
variable "target_group_arn" {}
variable "component" {}
variable "route53_zone_id" {}
variable "enable_https" {}
variable "certificate_arn" {}
variable "ingress" {}
variable "dns_name" {
  default = null
}