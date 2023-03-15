output "load_balancer_ip" {
  value = module.lb-http.external_ip
}

output "db_ip" {
  value = module.pg_db.private_ip_address
}

output "cloud_run_instance_url" {
  value = google_cloud_run_service.lp.status.0.url
}