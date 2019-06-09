provider "aws" {
  region = "${var.region}"
}


terraform {
  backend "s3" {
    bucket = "${var.terraform_bucket}"
    key = "${var.site_module_state_path}"
    dynamodb_table = "tf-cloudschool-env"
    region = "${var.region}"
  }
}


data "terraform_remote_state" "site" {
  backend = "s3"
  config {
    bucket = "${var.terraform_bucket}"
    key = "${var.site_module_state_path}"
  }
}

module "clouschool-app" {
  source = "git::ssh://??.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  instance_type = "t2.micro"
  additional_sgs = "${module.consul.consul_sg_id}"
  exchange_cluster_size = 2
}
