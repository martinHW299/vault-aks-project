# modules/postgresql/outputs.tf

output "server_fqdn" {
  description = "Host de PostgreSQL accesible desde dentro del cluster"
  value       = "postgresql.${var.namespace}.svc.cluster.local"
}

output "database_name" {
  value = var.db_name
}
