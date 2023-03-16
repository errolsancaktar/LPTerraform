
## Build out the basics ##
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "6.0.1"

  project_id   = module.project-services.project_id
  network_name = "lp"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name      = "lp-pub"
      subnet_ip        = "10.10.0.0/28"
      subnet_region    = var.regionid
      subnet_flow_logs = "false"
      description      = "Public VPC"
    },
    {
      subnet_name           = "lp-pvt"
      subnet_ip             = "10.10.1.0/28"
      subnet_region         = var.regionid
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Private VPC"
    }
  ]
  depends_on = [time_sleep.wait_60_seconds]
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [module.project-services.project_id]
  create_duration = "60s"
}

## Create NEG for LB ##
resource "google_compute_region_network_endpoint_group" "lp_neg" {
  name                  = "${var.name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.regionid
  cloud_run {
    service = google_cloud_run_service.lp.name
  }
}


## Implement LB ##
module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = ">=5.0"

  project = var.projectid
  name    = "${var.name}-lb"

  #managed_ssl_certificate_domains = ["YOUR_DOMAIN.COM"]
  ssl            = false
  https_redirect = false

  backends = {
    default = {
      protocol                = "HTTP"
      port_name               = "http"
      compression_mode        = null
      custom_response_headers = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.lp_neg.id
        }
      ]

      enable_cdn = false

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }

      description            = null
      custom_request_headers = null
      security_policy        = null
    }
  }
}

module "cloud-nat" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 1.2"
  region  = var.regionid
  project = var.projectid
  name    = "lpnat"
  network = module.vpc.network_name
  #  subnetwork = module.vpc.subnets["${var.regionid}/lp-pvt"].name
  nats = [{
    name = "my-nat-gateway"
  }]
}

## VPC Connector for CR ##
resource "google_vpc_access_connector" "lp-connector" {
  provider = google-beta
  name     = "run-vpc"
  subnet {
    name       = module.vpc.subnets["${var.regionid}/lp-pvt"].name
    project_id = var.projectid
  }
  machine_type = "e2-micro"
  region       = var.regionid
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

## IP Block For peering ##
resource "google_compute_global_address" "private_ip_block" {
  name          = "private-ip-block"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 20
  network       = module.vpc.network_id
}


## Private Connector ##
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}