## Generate PGDB PW ##
resource "random_password" "db" {
  length    = 36
  min_upper = 5
  min_lower = 5
  special   = false
}


module "pg_db" {
  source           = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version          = ">=14.0.1"
  name             = var.name
  region           = var.regionid
  zone             = var.zoneid
  project_id       = var.projectid
  database_version = "POSTGRES_14"

  database_deletion_policy = "ABANDON" ## Fix for postgres user deletion race condition ##
  tier                     = "db-g1-small"
  availability_type        = "REGIONAL"

  user_name     = "lpuser"
  user_password = random_password.db.result

  db_charset   = "UTF8"
  db_collation = "en_US.UTF8"

  db_name             = var.name
  deletion_protection = false
  ip_configuration = {
    ipv4_enabled       = false
    private_network    = module.vpc.network_id
    require_ssl        = false
    allocated_ip_range = null
    authorized_networks = [
      {
        "name" : "sample-gcp-health-checkers-range",
        "value" : "130.211.0.0/28"
      }
    ]
  }
}