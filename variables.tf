variable "project_id" {
  type = string
}


variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_subnets" {
  type = list(map(string))
}

variable "instance_tpl_spec" {
  type = object({
    machine_type         = string
    startup_script       = string
    source_image_project = string
    source_image         = string
    tags                 = list(string)
  })
}

variable "router" {
  type = object({
    name     = string
    nat_name = string
    network  = string
    region   = string
    subnet   = string
  })
}


variable "member" {
  type = string
}

