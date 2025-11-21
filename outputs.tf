output "swarm_status" {
  description = "Docker Swarm status"
  value       = data.external.swarm_status.result
}

output "swarm_initialized" {
  description = "Swarm initialization status"
  value       = length(terraform_data.swarm_init) > 0 ? "initialized" : "active"
}

output "traefik" {
  description = "Traefik module output"
  value       = module.traefik_stack
}

output "nginx" {
  description = "NGINX module output"
  value       = module.nginx_stack
}

output "portainer" {
  description = "Portainer module output"
  value       = module.portainer_stack
}

output "mongo" {
  description = "Mongo module output"
  value       = module.mongo_stack
}

output "postgres" {
  description = "Postgres module output"
  value       = module.postgres_stack
}

output "keycloak" {
  description = "Keycloak module output"
  value       = module.keycloak_stack
}

output "kafka" {
  description = "Kafka module output"
  value       = module.kafka_stack
}

output "maildev" {
  description = "Maildev module output"
  value       = module.maildev_stack
}

output "temporal" {
  description = "Temporal module output"
  value       = module.temporal_stack
}

output "localstack" {
  description = "LocalStack module output"
  value       = module.localstack_stack
}

output "prometheus" {
  description = "Prometheus module output"
  value       = module.prometheus_stack
}

output "grafana" {
  description = "Grafana module output"
  value       = module.grafana_stack
}