variable "stack_service_replicas_env_config" {
  description = <<-EOT
    Defines the number of replicas for each service within their respective stacks, and
    configures environment variables that are passed to Docker Compose files for dynamic scaling.
  EOT
  type        = map(number)
  default = {
    MONGO1_REPLICAS     = 1
    MONGO2_REPLICAS     = 0
    MONGO3_REPLICAS     = 0
    MONGO_INIT_REPLICAS = 0
    POSTGRES_REPLICAS   = 1
    REDIS_REPLICAS      = 1
    INFLUXDB_REPLICAS   = 1
    NEO4J_REPLICAS      = 1
    KEYCLOAK_REPLICAS   = 1
    KAFKA_REPLICAS      = 0
    MAILDEV_REPLICAS    = 1
    TEMPORAL_REPLICAS   = 1
    LOCALSTACK_REPLICAS = 1
    PROMETHEUS_REPLICAS = 1
    GRAFANA_REPLICAS    = 1
  }
}

variable "mongo_keyfile" {
  type        = string
  default     = null
  sensitive   = true
  description = "MongoDB keyfile"
}

variable "mongo_username" {
  type        = string
  default     = "mongo"
  sensitive   = true
  description = "MongoDB username"
}

variable "mongo_password" {
  type        = string
  default     = "mongo"
  sensitive   = true
  description = "MongoDB password"
}

variable "postgres_user" {
  type        = string
  default     = "postgres"
  description = "PostgreSQL user"
}

variable "postgres_password" {
  type        = string
  default     = "postgres"
  sensitive   = true
  description = "PostgreSQL password"
}

variable "redis_username" {
  type        = string
  default     = "redis"
  description = "Redis username"
}

variable "redis_password" {
  type        = string
  default     = "redis"
  sensitive   = true
  description = "Redis password"
}

variable "influxdb_username" {
  type        = string
  default     = "influxdb"
  sensitive   = true
  description = "InfluxDB username"
}

variable "influxdb_password" {
  type        = string
  default     = "influxdb"
  sensitive   = true
  description = "InfluxDB password"
}

variable "neo4j_auth" {
  type        = string
  default     = "neo4j/your_password"
  sensitive   = true
  description = "Neo4j auth"
}

variable "keycloak_admin_username" {
  type        = string
  default     = "keycloak"
  sensitive   = true
  description = "Keycloak username"
}

variable "keycloak_admin_password" {
  type        = string
  default     = "keycloak"
  sensitive   = true
  description = "Keycloak password"
}

variable "maildev_username" {
  type        = string
  default     = "maildev"
  sensitive   = true
  description = "Maildev username"
}

variable "maildev_password" {
  type        = string
  default     = "maildev"
  sensitive   = true
  description = "Maildev password"
}

variable "access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
  default     = "test"
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
  default     = "test"
}

variable "aws_profile" {
  description = "AWS Profile"
  type        = string
  default     = "localstack"
}

variable "aws_s3_endpoint" {
  description = "AWS S3 endpoint"
  type        = string
  default     = "http://localhost:4566"
}