variable "project_name" {
  type    = string
  default = "saa-scalable-web"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "true = one NAT GW (cheaper, not HA). false = one per AZ (production)."
  type        = bool
  default     = false
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 6
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_skip_final_snapshot" {
  description = "Set false in real production."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "alert_email" {
  description = "Email for SNS alarm notifications (leave empty to skip subscription)."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Existing Route 53 public hosted zone (e.g. example.com). Empty = no custom DNS/HTTPS on ALB."
  type        = string
  default     = ""
}
