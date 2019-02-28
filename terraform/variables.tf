variable "project_name" {
  default = "TerraformBB"
}


variable "subnet_ids" {
  default = ["subnet-0a7ae8ef5d6129581", "subnet-0b959ab0bbe851a90"]
}

variable "vpc_id" {
  default = "vpc-03761ce73a72a79ad"
}

variable "ec2_keypair_name" {
  default = "shaungc-ecs"
}

variable "task_container_name_nodejs" {
  default = "web"
}

variable "task_container_name_nginx" {
  default = "nginx"
}

variable "ssl_certificate_arn" {
    # using *.shaungc.com
  default = "arn:aws:acm:us-east-2:368061806057:certificate/1a4f64b3-d741-41c9-8ade-7b268e9ca28d"
}
