locals {
  name   = "${var.cluster_name}-${var.envirnoment}"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name    = local.name
    Owner   = "HashanR"
    Department = "Engineering"
  }
}