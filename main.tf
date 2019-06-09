terraform {
  backend "s3" {
    bucket = "???-cloudschool-tf-state"
    key = "site/terraform.tfstate" // in modules
    lock_table = "tf-cloudschool-env"
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
  chef_server_url = "https://chef-canary.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  instance_type = "c3.xlarge"
  additional_sgs = "${module.consul.consul_sg_id}"
  exchange_cluster_size = 2
}

/*
resource "consul_keys" "slave-db" {
    key {
        path = "db/slave/ip"
        value = "${module.main-db.private_ip}"
    }
}
*/


/*resource "aws_route53_zone" "main" {
  name = "${data.terraform_remote_state.site.environment}.net"
  comment = "main ${data.terraform_remote_state.site.environment} environment dns"
}


# Hack for qa presto dmp data storage
resource "aws_s3_bucket" "dmp" {
  bucket = "ia-qa-dmp"
  acl    = "private"
}
*/


/*


module "zookeeper" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-zookeeper.git"
  chef_server_hostname = "chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  additional_sgs = [ "${data.terraform_remote_state.site.dummy_sg_id}" ]
  additional_client_source_sgs  = [ "${data.terraform_remote_state.site.dummy_sg_id}" ]
}

module "kafka" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-kafka.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  additional_sgs = "${module.zookeeper.clients_sg_id},${module.consul.consul_sg_id}"
  chef_server_url = "https://chef-qa.inner-active.mobi/organizations/ia-qa"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  chef_validation_client = "${data.terraform_remote_state.site.environment}-validator"
  provisioner_ssh_key_path = "${var.bootstrap_ssh_key_path}"
}

module "aerospike-dmp" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-aerospike.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  ami = "ami-49c9295f"
  owner = "Data"
  additional_sgs = [ "sg-c8f1f7b3" ]
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  instances = 1
  disk_partitions = <<EOF
- [100, 83]
  EOF
  instance_type = "i3.4xlarge"
  cloudinit = "aerospike-dmp.cloudinit"
  chef_role = "aerospike-dmp"
  cluster_name = "aerospike-dmp"
}

module "sid" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-sid.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_sgs = [ "${module.consul.consul_sg_id}", "${module.main-db.clients_sg_id}" ]
  instances = 1
  instance_type = "m4.large"
}


module "spark_streaming" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-spark-streaming.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_sgs = "${module.kafka.clients_sg_id},${module.zookeeper.clients_sg_id},${module.main-db.clients_sg_id}"
  master_ip = "172.29.128.10"
  master_instance_type = "c3.large"
  worker_instance_type = "c3.large"
  cluster_size = "2"
}

# module "spark_batch" {
#  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-spark-batch.git"
#  terraform_bucket = "${var.terraform_bucket}"
#  site_module_state_path = "${var.site_module_state_path}"
#  chef_server_url = "https://chef-qa.inner-active.mobi"
#  chef_validation_pem_path = "${var.chef_validation_pem_path}"
#  additional_sgs = "${module.main-db.clients_sg_id}"
#  master_ip = "172.29.128.11"
#  master_instance_type = "c3.large"
#  worker_instance_type = "c3.large"
#  cluster_size = "2"
# }

module "cassandra_spark" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-cassandra_spark.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_sgs = ["${module.consul.consul_sg_id}"]
  instance_type = "c3.xlarge"
  cluster_size  = 4
}

module "ftknox_commons" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-ftknox_commons.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
}

module "ftknox_mmxkafka" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-ftknox.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_sgs = "${module.kafka.clients_sg_id},${module.zookeeper.clients_sg_id},${module.ftknox_commons.ftknox_sg_id}"
  instance_name = "Mmx-Consumer"
  role_name = "kafka-mmx-consumer"
  cluster_base_size = "1"
}
module "ftknox_mmxvideo" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-ftknox.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_sgs = "${module.kafka.clients_sg_id},${module.zookeeper.clients_sg_id},${module.ftknox_commons.ftknox_sg_id}"
  instance_name = "Mmx-Video-Consumer"
  role_name = "kafka-mmx-video-consumer"
  cluster_base_size = "1"
}

module "mock" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-mock.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  mock_private_ip = "172.29.20.20"

}

#module "spark_carpet" {
#  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-spark-carpet.git"
#  terraform_bucket = "${var.terraform_bucket}"
#  site_module_state_path = "${var.site_module_state_path}"
#  chef_server_url = "https://chef-qa.inner-active.mobi"
#  chef_validation_pem_path = "${var.chef_validation_pem_path}"
#  additional_sgs = "${module.kafka.clients_sg_id},${module.zookeeper.clients_sg_id}"
#  master_instance_type = "c3.2xlarge"
#  worker_instance_type = "c3.xlarge"
#}

module "huracan" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-huracan.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_sgs = [ "${module.kafka.clients_sg_id}" ]
}

module "hdp" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-hdp.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_source_sgs = "${list(data.terraform_remote_state.site.dummy_sg_id)}"
  additional_sgs = [ "${module.kafka.clients_sg_id}", "${module.zookeeper.clients_sg_id}", "${module.cassandra_spark.cassandra_clients_id}", "${module.consul.consul_sg_id}" ]
  hdp_instance_type = "m3.xlarge"
  hdp_cluster_size = 4
  hdp_sda_size = 24
  hdp_datanode_cluster_size = 4
  hdp_datanode_instance_type = "c3.4xlarge"
}

/*
  hdp-scheduler is a distributed scheduler for hadoop jobs (chiron)
  module provision following resources:
    - azkaban master ec2 instances
    - public (external) loadblanacer
    - private (internal) RDS (mysql) and provision azkaban database
  provision can be controlled via variables - https://bitbucket.org/inneractive-ondemand/tf-azkaban/src/master/variables.tf?fileviewer=file-view-default
*/
/*module "hdp-scheduler" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-azkaban.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  cluster_name = "hdp-scheduler-qa"
  sg_consul_clients = "${module.consul.consul_sg_id}"
  sg_worker_clients = "${module.hdp.hdp_sg_id}"
}


module "console" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-console.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  inneractive_com_ssl_cert = "arn:aws:iam::311878954612:server-certificate/inner-active_2016"
  additional_sgs = "${module.main-db.clients_sg_id},${module.consul.consul_sg_id},${module.cassandra_spark.cassandra_clients_id}"
  collins_cluster_size = 1
  parker_cluster_size = 1
  collins_instance_type = "c3.xlarge"
  parker_instance_type = "c3.xlarge"
}

module "console-testing" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-console.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  additional_sgs = "${module.main-db.clients_sg_id},${module.consul.consul_sg_id},${module.cassandra_spark.cassandra_clients_id}"
  inneractive_com_ssl_cert = "arn:aws:iam::311878954612:server-certificate/inner-active_2016"
  collins_cluster_size = 1
  collins_instance_type = "c3.xlarge"
  collins_cluster_name = "collins-testing"
  collins_role_name = "collins-testing-qa"
  parker_cluster_size = 1
  parker_instance_type = "c3.xlarge"
  parker_cluster_name = "parker-testing"
  parker_role_name = "parker-testing-qa"
  pecan_instance_type = "c3.xlarge"
  pecan_cluster_size = 1
  pecan_enabled = true
  pecan_cluster_name = "pecan-testing"
  pecan_role_name = "pecan-testing-qa"
  create_s3_user = false
}

module "secor" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-secor.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  additional_sgs = "${module.kafka.clients_sg_id},${module.zookeeper.clients_sg_id}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
}



# end to end exchange - huracan - secor for client sdk testing
module "exchange-sdk" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-exchange.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  instance_type = "c3.xlarge"
  additional_sgs = "${module.elasticache.clients_sg_id},${module.main-db.clients_sg_id},${module.kafka.clients_sg_id},${module.aerospike-dmp.aerospike_clients_id},${module.consul.consul_sg_id}"
  cluster_name = "exchange-sdk"
  role = "Exchange-wrapper-ia-qa-sdk"
  cluster_size = 1
  standalone_exchange_role = "Exchange-wrapper-ia-qa-standalone"
  standalone_exchanges = 2
}
module "huracan-sdk" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-huracan.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  cluster_name = "huracan-sdk"
  role = "Huracan-ia-qa-sdk"
  additional_sgs = [ "${module.kafka.clients_sg_id}" ]
}
module "secor-sdk" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-secor.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  additional_sgs = "${module.kafka.clients_sg_id},${module.zookeeper.clients_sg_id}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  instances = 1
  role = "secor-ia-qa-sdk"
  cluster_name = "secor-sdk"
}


module "presto" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-presto.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_server_url = "https://chef-qa.inner-active.mobi"
  chef_client_version = "12.12.15"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  cluster_size = 4
  worker_instance_type = "c4.xlarge"
  additional_sgs = [ "${module.consul.consul_sg_id}", "${module.hdp.hdp_sg_id}" ]
  master_instance_type = "m4.2xlarge"
}

module "rundeck" {
  source = "git::ssh://git@bitbucket.org/inneractive-ondemand/tf-rundeck.git"
  terraform_bucket = "${var.terraform_bucket}"
  site_module_state_path = "${var.site_module_state_path}"
  chef_hostname = "chef-qa.inner-active.mobi"
  chef_client_version = "12.12.15"
  chef_validation_pem_path = "${var.chef_validation_pem_path}"
  db_username = "${var.rundeck_db_username}"
  db_password = "${var.rundeck_db_password}"
  s3_bucket = "ia-qa-rundeck"
}
*/