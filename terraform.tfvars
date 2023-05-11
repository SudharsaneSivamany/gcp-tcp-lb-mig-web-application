project_id = "<Project_ID>"

vpc_name = "vpc-name"

vpc_subnets = [
  {
    subnet_name   = "subnet-name-1"
    subnet_ip     = "cidr_bllock"
    subnet_region = "region"
    description   = "This subnet is for tcp lb service poc"
}]

region = "region"

instance_tpl_spec = {
  machine_type         = "e2-micro"
  startup_script       = "sudo apt-get update;sudo apt-get install -yq build-essential apache2"
  source_image_project = "ubuntu-os-cloud"
  source_image         = "ubuntu-1804-lts"
  tags                 = ["allow-lb-service"]
}


router = {
  name     = "" #Cloud Router Name to be used
  nat_name = "" #Name for Cloud NAT
  network  = "" #VPC Network Name
  region   = "" #Region for Cloud NAT
  subnet   = "" #subnet for having NAT
}

member = ""
