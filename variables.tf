variable "db_admin_password" {
  description = "Database admin password"
}


variable "terraform_bucket" {
  description = "Bucket for terraform remote state"
}

variable "site_module_state_path" {
  description = "Path to site module remote state"
}

/*variable "bootstrap_ssh_key_path" {
  description = <<EOS
Path to administrator ssh key.
This key should allow login to the admin user and will be used mainly for instance provisioning
and early configuration.
EOS
}


variable "rundeck_db_username" {
  type = "string"
  description = "user for rundeck backend database"
}

variable "rundeck_db_password" {
  type = "string"
  description = "password for rundeck backend database"
}
*/