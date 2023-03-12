output "load_balancer_ip" {
  value = module.lb-http.external_ip
}

output "db_pass" {
  value = random_password.db.result
  sensitive = true
}

output "db_ip" {
  value = google_sql_database_instance.main.private_ip_address
}

output "cloud_run_instance_url" {
  value = google_cloud_run_service.lp.status.0.url
}