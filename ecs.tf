data "aws_availability_zones" "available" {}

data "template_file" "task" {
  template = "${file("${path.module}/task.json")}"

  vars {
    keys_volume               = "service-storage"
    postgres_volume           = "service-storage"
    postgres_pwd              = "${var.postgres_pwd}"
    concourse_web_port        = "${var.concourse_web_port}"
    concourse_username        = "${var.concourse_username}"
    concourse_password        = "${var.concourse_password}"
    concourse_external_url    = "http://${aws_route53_record.ci.name}"
  }
}

resource "aws_key_pair" "concourse" {
  key_name   = "concourse-key"
  public_key = "${var.public_key}"
}

module "ecs_alb" {
  source                  = "github.com/mtranter/terraform-ecs-alb?ref=v0.17//module"
  ecs-alb-log-bucket      = "concourse.ecs.loging.mtranter.io"
  key_name                = "${aws_key_pair.concourse.key_name}"
  aws_region              = "${var.aws_region}"
  instance_name_prefix    = "concourse-ecs-"
  admin_cidr_ingress      = "80.7.136.0/24"
  min_instances           = 1
  desired_instances       = 1
}

resource "aws_ecs_task_definition" "concourse" {
  family                = "concourse"
  container_definitions = "${data.template_file.task.rendered}"

  volume {
    name      = "service-storage"
    host_path = "/container-state"
  }
}

resource "aws_ecs_service" "concourse" {
  name                                = "concourse"
  cluster                             = "${module.ecs_alb.ecs_cluster_id}"
  task_definition                     = "${aws_ecs_task_definition.concourse.arn}"
  desired_count                       = 1
  deployment_minimum_healthy_percent  = 1
  iam_role                            = "${module.ecs_alb.service_iam_role_arn}"

  load_balancer {
    target_group_arn       = "${aws_alb_target_group.concourse.id}"
    container_name = "concourse-web"
    container_port = "${var.concourse_web_port}"
  }
}

resource "aws_alb_target_group" "concourse" {
  name     = "concourse"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${module.ecs_alb.vpc_id}"
}

resource "aws_alb_listener" "auth" {
  load_balancer_arn = "${module.ecs_alb.alb_arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.concourse.id}"
    type             = "forward"
  }
}

data "aws_route53_zone" "selected" {
  name         = "${var.aws_route_zone}"
  private_zone = false
}

resource "aws_route53_record" "ci" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.aws_route53_record_domain}"
  type    = "A"

  alias {
    name                   = "${module.ecs_alb.alb_dns_name}"
    zone_id                = "${module.ecs_alb.alb_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_security_group_rule" "elb_to_concourse" {
  type            = "ingress"
  from_port       = "${var.concourse_web_port}"
  to_port         = "${var.concourse_web_port}"
  protocol        = "tcp"
  source_security_group_id     = "${module.ecs_alb.alb_security_group_id}"

  security_group_id = "${module.ecs_alb.instance_security_group_id}"
}
