resource "aws_ecs_service" "test-ecs-service" {
  name            = "${var.project_name}-test-vz-service"
  cluster         = "${aws_ecs_cluster.test-ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.test.family}:${max("${aws_ecs_task_definition.test.revision}", "${data.aws_ecs_task_definition.test.revision}")}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.ecs-service-role.name}"

  deployment_minimum_healthy_percent = 0 # default is 100
  deployment_maximum_percent = 100 # default is 200

  load_balancer {
    target_group_arn = "${aws_alb_target_group.http.id}"
    container_name   = "${var.task_container_name_nginx}"
    container_port   = "80"
  }

  depends_on = [
    # "aws_iam_role_policy.ecs-service",
    "aws_alb_listener.https",
  ]
}
