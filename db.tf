
## Create DB instance ##
resource "google_sql_database_instance" "main" {
  name             = "${var.name}-db"
  database_version = "POSTGRES_14"
  region           = "us-central1"
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  deletion_protection = false
  settings {
    tier = "db-g1-small"
    ip_configuration {
      ipv4_enabled    = false
      private_network = module.vpc.network_id
    }
  }
}


## Create DB ##
resource "google_sql_database" "lp-db" {
  name      = var.name
  instance  = google_sql_database_instance.main.name
  charset   = "utf8"
}

## Generate PGDB PW ##
resource "random_password" "db" {
  length    = 36
  min_upper = 5
  min_lower = 5
  special = false
}


## Create DB User ##
resource "google_sql_user" "this" {
  name     = "lpuser"
  instance = google_sql_database_instance.main.name
  password = random_password.db.result
}

