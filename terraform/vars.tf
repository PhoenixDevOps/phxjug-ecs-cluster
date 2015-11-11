# ------------------------------------------------------------------------------
# POPULATED BY LOCAL ENV VARS
# ------------------------------------------------------------------------------
# Define these variables as environment variables for your localdev by appending
# "TF_VAR_" to each of them.  For example, define TF_VAR_AWS_ACCESS_KEY_ID in your
# local environment.
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
variable "AWS_REGION" {}

# ------------------------------------------------------------------------------
# TFVARS PARAMETERS
# These variables are expected to be passed in by the operator when running
# "terraform apply"
# ------------------------------------------------------------------------------

# Name of the ECS Cluster (e.g. "josh" or "demo")
variable "cluster_name" {}

# The number of nodes to be included in the cluster.
variable "node_count" {}

# The EC2 Keypair Name used to SSH into any of the ECS instances
# This must be created manually in the AWS Web Console
variable "ec2_keypair_name" {}

# The EC2 Instance Type for ECS Nodes (e.g. "t2.medium")
variable "ecs_instance_type" {}

# ------------------------------------------------------------------------------
# CONSTANTS
# These values won't change often.
# ------------------------------------------------------------------------------
# AMI to be used for EC2 instances in the cluster.
variable "ecs_amis" {
  default = {
    us-east-1 = "ami-ddc7b6b7"
    us-west-1 = "ami-a39df1c3"
    us-west-2 = "ami-d74357b6"
  }
}

# Availability Zones for each region
# Sometimes an AWS region has 2 AZ's, sometimes 4
# Also, one AWS account may have a different set of AZ's than another
variable "availability_zones" {
  default = {
    us-east-1 = "us-east-1a,us-east-1b,us-east-1c,us-east-1d"
    us-west-1 = "us-west-1a,us-west-1b,us-west-1c"
    us-west-2 = "us-west-2a,us-west-2b,us-west-2c"
  }
}
