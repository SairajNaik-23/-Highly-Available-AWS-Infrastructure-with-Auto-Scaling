variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "ha-web"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.micro" # free-tier eligible in most regions
}

# Auto Scaling Group size
variable "asg_min_size" {
  type    = number
  default = 2 # at least one instance per AZ
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 6
}

variable "cpu_target_percent" {
  description = "Target average CPU % for the target tracking scaling policy"
  type        = number
  default     = 50
}

variable "alert_email" {
  description = "Email for CloudWatch alarm notifications (leave empty to skip)"
  type        = string
  default     = ""
}

# Route 53 (optional): set both to create app.example.com -> ALB
variable "domain_name" {
  description = "Existing Route 53 hosted zone, e.g. example.com (leave empty to skip)"
  type        = string
  default     = ""
}

variable "subdomain" {
  type    = string
  default = "app"
}
