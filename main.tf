terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.48.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.48.0"
    }
  }
}

provider "google" {
  project = var.projectid
  region  = var.regionid
  zone    = var.zoneid
}

provider "google-beta" {
  project = var.projectid
  region  = var.regionid
}

## Project Factory to build out the project and apis ##
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = ">= 14.2"

  project_id                  = var.projectid
  disable_services_on_destroy = false
  activate_apis = [
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "run.googleapis.com",
    "deploymentmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudresourcemanager.googleapis.com"

  ]
}



## Primary Cloud Run Instance
resource "google_cloud_run_service" "lp" {
  name     = "lp-service"
  location = var.regionid
  template {
    spec {
      containers {
        image = "ansemjo/speedtest"
        env {
          name  = "TZ"
          value = "America/Denver"
        }
        env {
          name  = "DATABASE"
          value = "postgresql://lpuser:${random_password.db.result}@${module.pg_db.private_ip_address}:5432/${var.name}"
        }
        env {
          name  = "SCHEDULE"
          value = "* * * * *"
        }
        env {
          name  = "TESTSERVER"
          value = "denver.speedtest.centurylink.net:8080"
        }
        ports {
          name           = "http1"
          container_port = 8000
          protocol       = "TCP"
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "2"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.lp-connector.name ## VPC Connector ##
      }
    }
  }
  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "all"
    }
  }

  autogenerate_revision_name = true
}

## Allow Unauth Invoke##
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.lp.location
  project  = google_cloud_run_service.lp.project
  service  = google_cloud_run_service.lp.name

  policy_data = data.google_iam_policy.noauth.policy_data

}


resource "google_cloud_run_service_iam_member" "lp-cr-svc" {
  location = google_cloud_run_service.lp.location
  project  = var.projectid
  service  = google_cloud_run_service.lp.name
  role     = "roles/run.invoker"
  member   = "allUsers"

}

