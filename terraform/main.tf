# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN ECS CLUSTER
# This Terraform template launches a simple EC2 Container Service cluster.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# SET AWS CREDENTIALS
# ------------------------------------------------------------------------------
# Configure the AWS connection used to provision resources
provider "aws" {
    access_key = "${var.AWS_ACCESS_KEY_ID}"
    secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
    region = "${var.AWS_REGION}"
    # Only this AWS Account ID may be operated on by this template
    #allowed_account_ids = ["###"]
}


# ------------------------------------------------------------------------------
# IAM ROLE FOR ECS NODES
# ------------------------------------------------------------------------------

# Create an IAM Role that can grant privileges on AWS resources to an EC2 instance
resource "aws_iam_role" "ecs_node" {
    name = "${var.cluster_name}-iam-ecs-node"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

# To assign an IAM Role to an EC2 instance, we actually need to assign the "IAM Instance Profile"
resource "aws_iam_instance_profile" "ecs_node" {
    name = "${var.cluster_name}-iam-ecs-node"
    roles = ["${aws_iam_role.ecs_node.name}"]
}

# Attach the "AmazonEC2ContainerServiceforEC2Role" Managed Policy
# Use this ManagedPolicy vs. an IAM Policy we create because AWS may update this in the future.
resource "aws_iam_policy_attachment" "ecs_node" {
    name = "ecs-node"
    roles = ["${aws_iam_role.ecs_node.name}"]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ------------------------------------------------------------------------------
# IAM ROLE FOR ECS SERVICE
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_service" {
    name = "${var.cluster_name}-iam-ecs-service"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      }
    }
  ]
}
EOF
}

# To assign an IAM Role to an EC2 instance, we actually need to assign the "IAM Instance Profile"
resource "aws_iam_instance_profile" "ecs_service" {
    name = "${var.cluster_name}-iam-ecs-service"
    roles = ["${aws_iam_role.ecs_service.name}"]
}

# Attach the "AmazonEC2ContainerServiceforEC2Role" Managed Policy
# Use this ManagedPolicy vs. an IAM Policy we create because AWS may update this in the future.
resource "aws_iam_policy_attachment" "ecs-service" {
    name = "ecs-node"
    roles = ["${aws_iam_role.ecs_service.name}"]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# ------------------------------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------------------------------

# Create the Security Group
resource "aws_security_group" "ecs_node" {
  name = "${var.cluster_name}-ecs-node-sg"
  description = "ECS Node"

  # Outbound Everything
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP (for non-ELB services)
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS (for non-ELB services)
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# AUTO SCALING GROUP + ELASTIC LOAD BALANCER
# ------------------------------------------------------------------------------

# Create a Load Balancer
resource "aws_elb" "demo_service" {
  name = "demo-service"
  availability_zones = ["${split(",", lookup(var.availability_zones, var.AWS_REGION))}"]
  security_groups = ["${aws_security_group.ecs_node.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 60

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/health/"
  }

  listener {
    instance_port = 9001
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }
}

# Create a Launch Configuration
resource "aws_launch_configuration" "ecs_node" {
  name = "ecs-node"
  image_id = "${lookup(var.ecs_amis, var.AWS_REGION)}"
  instance_type = "${var.ecs_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_node.name}"
  security_groups = ["${aws_security_group.ecs_node.id}"]
  key_name = "${var.ec2_keypair_name}"
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "ecs_nodes" {
  name = "ecs-nodes"
  min_size = "${var.node_count}"
  max_size = "${var.node_count}"
  availability_zones = ["${split(",", lookup(var.availability_zones, var.AWS_REGION))}"]
  launch_configuration = "${aws_launch_configuration.ecs_node.name}"
  load_balancers = ["${aws_elb.demo_service.name}"]
}

# ------------------------------------------------------------------------------
# ECS TASK DEFINITION FAMILY + ECS SERVICE
# ------------------------------------------------------------------------------

/*# Create a Task Definition Family
# - Actually, we're creating a single Task Definition, but this has the effect
#   of also creating a Task Definition Family
# - Choose an arbitrary initial docker image tag (version) since our deployment
#   process will replace these
resource "aws_ecs_task_definition" "demo_service" {
  family = "demo-service"
  container_definitions = "${file("files/ecs-task-definition.json")}"
}

# Create an ECS Service
resource "aws_ecs_service" "demo_service" {
  name = "demo-service"
  cluster = "default"
  task_definition = "${aws_ecs_task_definition.demo_service.arn}"
  desired_count = 2
  iam_role = "${aws_iam_role.ecs_node.arn}"

  load_balancer {
    elb_name = "${aws_elb.demo_service.id}"
    container_name = "phxjug-play-framework-demo"
    container_port = 9001
  }
}*/
