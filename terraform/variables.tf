variable "desired_capacity" {
  description = "Number of instances to launch in the ECS cluster."
  type        = number
  default     = 1
}

variable "maximum_capacity" {
  description = "Maximum number of instances that can be launched in the ECS cluster."
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type for ECS launch configuration."
  type        = string
  default     = "t2.micro"
}

variable "service_name" {
  description = "The name for the ECS service."
  type        = string
  default     = "flask-docker"
}

variable "ecr_image_url" {
  description = "The desired ECR image URL."
  type        = string
}


variable "vpc_id" {}

variable "subnet_id" {}

