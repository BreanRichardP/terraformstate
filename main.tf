terraform {
  backend "s3" {
    bucket = "taskexecutionforterraform"
    key = "terraform/terraform.tfstate"
    region = "us-west-2"
    dynamodb_table = "terraform-dynamodb-lock-state"
  }
}
provider "aws" {
  region = "us-west-2"
}
module "my_vpc" {
  source           = "../Terraform 5/modules/vpc"
  vpc_cidr         = "192.168.0.0/16"
  instance_tenancy = "default"
  subnet_cidr      = "192.168.0.0/16"
  vpc_id           = module.my_vpc.vpc_id

}

module "my_ec2" {
  source        = "../Terraform 5/modules/ec2"
  ec2_count     = "1"
  ami_id        = "ami-0ca285d4c2cda3300"
  instance_type = "t2.micro"
  subnet_id     = module.my_vpc.subnet_id
}

resource "aws_dynamodb_table" "terraform_statelock" {
  name = "terraform-dynamodb-lock-state"
  billing_mode = "PROVISIONED"
  read_capacity = 20
  write_capacity = 20
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  ttl {
    attribute_name = "TimeToExist"
    enabled = false
  }
  global_secondary_index {
    name               = "LockIDindex"
    hash_key           = "LockID"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["LockID"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "test"
  }
}
resource "aws_s3_bucket" "terraform" {
  bucket = "taskexecutionforterraform"

  tags = {
    Name        = "My bucket"
    Environment = "test"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.terraform.id
  acl    = "private"
}

