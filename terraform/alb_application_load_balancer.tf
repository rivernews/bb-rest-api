
resource "aws_alb" "main" {
  name    = "${var.project_name}-alb-ecs"
  subnets = ["${var.subnet_ids[0]}", "${var.subnet_ids[1]}"]

  # subnets         = ["${module.new-vpc.public_subnets}"]
  security_groups = ["${aws_security_group.public_alb.id}"]

  # security_groups = ["${module.new-vpc.default_security_group_id}"]
}


# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "public_alb" {
  name        = "${var.project_name}_public_alb"
  description = "Allow public traffic for Application Load Balancer."
  vpc_id      = "${var.vpc_id}"

  # for allowing health check traffic
  ingress {
    from_port = 32768 # ephemeral port range: https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PortMapping.html
    # to_port     = 61000
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // anywhere
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
  }

  ingress {
    description = "Bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // anywhere
    self        = false
  }

  # allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Use only https to allow only incoming outside https request to LB. 
# For internal traffic LB -> target group -> service, just use http.
# resource "aws_alb_listener" "http" {
#   load_balancer_arn = "${aws_alb.main.id}"
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     target_group_arn = "${aws_alb_target_group.http.id}"
#     type             = "forward"
#   }
# }

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.ssl_certificate_arn}"

  default_action {
    # target_group_arn = "${aws_alb_target_group.https.id}"
    target_group_arn = "${aws_alb_target_group.http.id}"
    type             = "forward"
  }
}

# https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check
resource "aws_alb_target_group" "http" {
  name     = "${var.project_name}-alb-tg-http"
  # port     = 80 # should be same as alb's listener (443) OR container's port (80)??
  # protocol = "HTTP"

  #   vpc_id   = "${module.new-vpc.vpc_id}"
  vpc_id = "${var.vpc_id}"

  health_check {
      path = "/"
      matcher = "200-299"
      port = "traffic-port" # port number or "traffic-port" (default), required for dynamic host port for container: https://aws.amazon.com/premiumsupport/knowledge-center/dynamic-port-mapping-ecs/
      # protocol = "HTTP" # default

      interval = 20
      timeout = 10
      healthy_threshold = 2
      unhealthy_threshold = 3
  }

  lifecycle {
      create_before_destroy = true # avoid error: target is currently in use by a listener or a rule, see https://github.com/terraform-providers/terraform-provider-aws/issues/1315
  }
}

# https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check
# resource "aws_alb_target_group" "https" {
#   name     = "${var.project_name}-alb-tg-https"
#   port     = 443
#   protocol = "HTTPS"

#   vpc_id = "${var.vpc_id}"

#   health_check {
#       path = "/"
#       matcher = "200-299"
#       port = 443 # or "traffic-port" (default)
#       protocol = "HTTPS" # default

#       interval = 20
#       timeout = 10
#       healthy_threshold = 2
#       unhealthy_threshold = 3
#   }
# }