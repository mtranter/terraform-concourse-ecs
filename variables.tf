variable "aws_region" {}
variable "public_key" {}
variable "concourse_password" {}
variable "postgres_pwd" {}
variable "concourse_username" {}
variable "concourse_web_port" {
  default = 8080
}
variable "aws_route_zone" {}

variable "aws_route53_record_domain" {}
