data "aws_ecr_repository" "nodejs" {
  name = "bb-diner/nodejs"
#   name = "${aws_ecr_repository.service.name}"
#   depends_on      = ["aws_ecr_repository.service"]
  
  # other available vars exposed: (https://www.terraform.io/docs/providers/aws/r/ecr_repository.html)
  # arn
  # registry_id
  # repository_url
  # tags
}

data "aws_ecr_repository" "nginx" {
  name = "bb-diner/nginx"
}


data "aws_ecs_task_definition" "test" {
  task_definition = "${aws_ecs_task_definition.test.family}"
  depends_on      = ["aws_ecs_task_definition.test"]
}

resource "aws_ecs_task_definition" "test" {
  family                   = "${var.project_name}-family"
  network_mode             = "bridge"                     # The valid values are none, bridge, awsvpc, and host. The default Docker network mode is bridge.
  requires_compatibilities = ["EC2"]
  execution_role_arn       = "arn:aws:iam::368061806057:role/ecsTaskExecutionRoleForEcsCli" # required if container secret

  # json injection using EOF: https://github.com/terraform-providers/terraform-provider-aws/issues/3970
  # json injection using JSON: https://github.com/terraform-providers/terraform-provider-aws/issues/632
  # aws spec: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
  # aws wizard setup: https://medium.freecodecamp.org/how-to-deploy-a-node-js-application-to-amazon-web-services-using-docker-81c2a2d7225b
  container_definitions = <<JSON
[
     {
      "name": "${var.task_container_name_nginx}",
      "image": "${data.aws_ecr_repository.nginx.repository_url}:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/BBDiner",
          "awslogs-region": "us-east-2",
          "awslogs-stream-prefix": "ecs-${var.task_container_name_nginx}"
        }
      },
      "portMappings": [
        {
          "hostPort": 80,
          "protocol": "tcp",
          "containerPort": 80
        }
      ],
      "command": [],
      "cpu": 64,
      "environment": [],
      "mountPoints": [],
      "dockerSecurityOptions": [],
      "memory": null,
      "memoryReservation": 64,
      "volumesFrom": [],
      "healthCheck": {
        "retries": 3,
        "command": [
          "CMD-SHELL",
          "exit 0"
        ],
        "timeout": 5,
        "interval": 10,
        "startPeriod": null
      },
      "essential": true,
      "links": ["${var.task_container_name_nodejs}"],
      "privileged": false
    },
    {
      "name": "${var.task_container_name_nodejs}",
      "image": "${data.aws_ecr_repository.nodejs.repository_url}:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/BBDiner",
          "awslogs-region": "us-east-2",
          "awslogs-stream-prefix": "ecs-${var.task_container_name_nodejs}"
        }
      },
      "command": [],
      "cpu": 64,
      "environment": [],
      "mountPoints": [],
      "secrets": [
        {
          "valueFrom": "arn:aws:ssm:us-east-2:368061806057:parameter/bb-diner/MONGODB_URI",
          "name": "MONGODB_URI"
        },
        {
          "valueFrom": "arn:aws:ssm:us-east-2:368061806057:parameter/bb-diner/NODE_ENV",
          "name": "NODE_ENV"
        }
      ],
      "dockerSecurityOptions": [],
      "memory": null,
      "memoryReservation": 64,
      "volumesFrom": [],
      "essential": true,
      "privileged": false
    }
]
JSON

  # secret: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
  # aws parameter store: https://us-east-2.console.aws.amazon.com/systems-manager/parameters?region=us-east-2
  # aws key management servoce: https://us-east-2.console.aws.amazon.com/kms/home?region=us-east-2#/kms/home

  depends_on = [
      "data.aws_ecr_repository.nginx", 
      "data.aws_ecr_repository.nodejs",
    ]
  #   volume {
  #     name      = "service-storage"
  #     host_path = "/ecs/service-storage"
  #   }
  placement_constraints {
    type       = "memberOf"
    # expression = "attribute:ecs.availability-zone in [us-east-2a]" # free tier

    expression = "attribute:ecs.availability-zone in [us-east-2a, us-east-2b]"
  }
}
