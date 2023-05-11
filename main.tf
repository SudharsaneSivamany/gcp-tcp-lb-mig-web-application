module "shared-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "5.1.0"

  project_id   = var.project_id
  network_name = var.vpc_name
  subnets      = var.vpc_subnets
}

module "firewall_rules" {
  depends_on   = [module.shared-vpc]
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = var.vpc_name

  rules = [
    {
      name                    = "allow-http-ingress-${var.vpc_name}"
      description             = "Allows TCP connections from any source to any instance on the network using port 80"
      direction               = "INGRESS"
      priority                = 65534
      ranges                  = ["0.0.0.0/0"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [{
        protocol = "tcp"
        ports    = ["80"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}


module "instance_template" {
  source               = "terraform-google-modules/vm/google//modules/instance_template"
  subnetwork           = module.shared-vpc.subnets_self_links[0]
  project_id           = var.project_id
  region               = var.region
  service_account      = null
  machine_type         = var.instance_tpl_spec.machine_type
  startup_script       = var.instance_tpl_spec.startup_script
  source_image_project = var.instance_tpl_spec.source_image_project
  source_image         = var.instance_tpl_spec.source_image
  tags                 = var.instance_tpl_spec.tags
}


module "managed_instance_group" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  project_id        = var.project_id
  region            = var.region
  target_size       = 2
  hostname          = "mig-simple"
  instance_template = module.instance_template.self_link
  target_pools      = [module.load_balancer.target_pool]
  named_ports = [{
    name = "tcp"
    port = 80
  }]
}


module "load_balancer" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "~> 2.0.0"
  project      = var.project_id
  region       = var.region
  name         = "load-balancer"
  service_port = 80
  target_tags  = ["allow-lb-service"]
  network      = module.shared-vpc.network_name
}


module "cloud_router" {
  depends_on = [module.shared-vpc]
  source     = "terraform-google-modules/cloud-router/google"
  name       = var.router.name
  project    = var.project_id
  region     = var.router.region
  network    = var.router.network
}

module "cloud-nat" {
  depends_on                         = [module.cloud_router]
  source                             = "terraform-google-modules/cloud-nat/google"
  project_id                         = var.project_id
  region                             = var.router.region
  router                             = var.router.name
  name                               = var.router.nat_name
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetworks = [{
    name                     = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.router.region}/subnetworks/${var.router.subnet}"
    source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
    secondary_ip_range_names = []
  }]
}

resource "google_project_iam_custom_role" "my-custom-role" {
  role_id     = "vmrestart"
  title       = "My Custom Role"
  description = "A description"
  permissions = ["compute.instances.stop", "compute.instances.start"]
  project     = var.project_id

}


resource "google_project_iam_member" "custom_role_member" {

  project = var.project_id
  role    = google_project_iam_custom_role.my-custom-role.name
  member  = var.member

}

