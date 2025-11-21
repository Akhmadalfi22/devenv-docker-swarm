# Check if swarm is active
data "external" "swarm_status" {
  program = [
    "bash", "-c",
    <<EOT
      STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo 'inactive')
      echo "{\"status\":\"$STATUS\"}"
    EOT
  ]
}

resource "random_bytes" "mongo_keyfile" {
  length = 756
}

locals {
  mongo_keyfile = var.mongo_keyfile != null ? var.mongo_keyfile : random_bytes.mongo_keyfile.base64
}

/*provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "us-east-1"

  profile = var.aws_profile
  skip_credentials_validation = true
  skip_metadata_api_check = true
  s3_use_path_style = true

  endpoints {
    s3 = var.aws_s3_endpoint
  }
}*/

# Initialize swarm
resource "terraform_data" "swarm_init" {
  count = data.external.swarm_status.result["status"] == "inactive" ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      echo "Running swarm init..."
      docker swarm init --task-history-limit=0
    EOT
  }

  triggers_replace = {
    swarm_status = data.external.swarm_status.result["status"]
  }
}

# Wait for swarm to be ready
resource "terraform_data" "swarm_ready" {
  provisioner "local-exec" {
    command = "sleep 3"
  }

  depends_on = [terraform_data.swarm_init]
}

module "traefik_stack" {
  source = "./modules/docker-swarm-stack"

  stack_name   = "traefik"
  compose_file = "docker-compose.traefik.yml"

  depends_on = [terraform_data.swarm_ready]
}

module "nginx_stack" {
  source = "./modules/docker-swarm-stack"

  stack_name   = "nginx"
  compose_file = "docker-compose.nginx.yml"

  depends_on = [terraform_data.swarm_ready]
}

module "portainer_stack" {
  source = "./modules/docker-swarm-stack"

  stack_name   = "portainer"
  compose_file = "docker-compose.portainer.yml"

  depends_on = [terraform_data.swarm_ready, module.traefik_stack]
}

module "mongo_stack" {
  count = var.stack_service_replicas_env_config.MONGO1_REPLICAS + var.stack_service_replicas_env_config.MONGO2_REPLICAS + var.stack_service_replicas_env_config.MONGO2_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "mongo"
  compose_file = "docker-compose.mongo.yml"
  replicas = {
    MONGO1_REPLICAS = var.stack_service_replicas_env_config.MONGO1_REPLICAS
    MONGO2_REPLICAS = var.stack_service_replicas_env_config.MONGO2_REPLICAS
    MONGO3_REPLICAS = var.stack_service_replicas_env_config.MONGO3_REPLICAS
  }

  secrets = {
    mongo-keyfile = {
      name  = "mongo-keyfile"
      value = local.mongo_keyfile
    }
    mongo-username = {
      name  = "mongo-username"
      value = var.mongo_username
    }
    mongo-password = {
      name  = "mongo-password"
      value = var.mongo_password
    }
  }

  depends_on = [terraform_data.swarm_ready]
}

module "postgres_stack" {
  count = var.stack_service_replicas_env_config.POSTGRES_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "postgres"
  compose_file = "docker-compose.postgres.yml"
  replicas = {
    POSTGRES_REPLICAS = var.stack_service_replicas_env_config.POSTGRES_REPLICAS
  }

  secrets = {
    postgres-user = {
      name  = "postgres-user"
      value = var.postgres_user
    }
    postgres-password = {
      name  = "postgres-password"
      value = var.postgres_password
    }
  }

  depends_on = [terraform_data.swarm_ready]
}

module "redis_stack" {
  count = var.stack_service_replicas_env_config.REDIS_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "redis"
  compose_file = "docker-compose.redis.yml"
  replicas = {
    REDIS_REPLICAS = var.stack_service_replicas_env_config.REDIS_REPLICAS
  }

  secrets = {
    redis-username = {
      name  = "redis-username"
      value = var.redis_username
    }
    redis-password = {
      name  = "redis-password"
      value = var.redis_password
    }
  }

  depends_on = [terraform_data.swarm_ready]
}

module "influxdb_stack" {
  count = var.stack_service_replicas_env_config.INFLUXDB_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "influxdb"
  compose_file = "docker-compose.influxdb.yml"
  replicas = {
    INFLUXDB_REPLICAS = var.stack_service_replicas_env_config.INFLUXDB_REPLICAS
  }

  secrets = {
    influxdb-username = {
      name  = "influxdb-username"
      value = var.influxdb_username
    }
    influxdb-password = {
      name  = "influxdb-password"
      value = var.influxdb_password
    }
  }

  depends_on = [terraform_data.swarm_ready]
}

module "neo4j_stack" {
  count = var.stack_service_replicas_env_config.NEO4J_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "neo4j"
  compose_file = "docker-compose.neo4j.yml"
  replicas = {
    NEO4J_REPLICAS = var.stack_service_replicas_env_config.NEO4J_REPLICAS
  }

  secrets = {
    neo4j-auth = {
      name  = "neo4j-auth"
      value = var.neo4j_auth
    }
  }

  depends_on = [terraform_data.swarm_ready]
}

module "keycloak_stack" {
  count = var.stack_service_replicas_env_config.KEYCLOAK_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "keycloak"
  compose_file = "docker-compose.keycloak.yml"
  replicas = {
    KEYCLOAK_REPLICAS = var.stack_service_replicas_env_config.KEYCLOAK_REPLICAS
  }

  secrets = {
    keycloak-admin-username = {
      name  = "keycloak-admin-username"
      value = var.keycloak_admin_username
    }
    keycloak-admin-password = {
      name  = "keycloak-admin-password"
      value = var.keycloak_admin_password
    }
  }

  wait_for = ["postgres"]

  depends_on = [terraform_data.swarm_ready, module.traefik_stack, module.postgres_stack]
}

module "kafka_stack" {
  count = var.stack_service_replicas_env_config.KAFKA_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "kafka"
  compose_file = "docker-compose.kafka.yml"
  replicas = {
    KEYCLOAK_REPLICAS = var.stack_service_replicas_env_config.KEYCLOAK_REPLICAS
  }

  depends_on = [terraform_data.swarm_ready, module.traefik_stack]
}

module "maildev_stack" {
  count = var.stack_service_replicas_env_config.MAILDEV_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "maildev"
  compose_file = "docker-compose.maildev.yml"
  replicas = {
    MAILDEV_REPLICAS = var.stack_service_replicas_env_config.MAILDEV_REPLICAS
  }

  secrets = {
    maildev-username = {
      name  = "maildev-username"
      value = var.maildev_username
    }
    maildev-password = {
      name  = "maildev-password"
      value = var.maildev_password
    }
  }

  depends_on = [terraform_data.swarm_ready, module.traefik_stack]
}

module "temporal_stack" {
  count = var.stack_service_replicas_env_config.TEMPORAL_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "temporal"
  compose_file = "docker-compose.temporal.yml"
  replicas = {
    TEMPORAL_REPLICAS = var.stack_service_replicas_env_config.TEMPORAL_REPLICAS
  }

  wait_for = ["postgres"]

  depends_on = [terraform_data.swarm_ready, module.nginx_stack, module.postgres_stack]
}

module "localstack_stack" {
  count = var.stack_service_replicas_env_config.LOCALSTACK_REPLICAS

  source = "./modules/docker-swarm-stack"

  stack_name   = "localstack"
  compose_file = "docker-compose.localstack.yml"
  replicas = {
    LOCALSTACK_REPLICAS = var.stack_service_replicas_env_config.LOCALSTACK_REPLICAS
  }

  depends_on = [terraform_data.swarm_ready]
}

/*module "aws" {
  source = "./modules/aws"

  depends_on = [module.localstack_stack]
}*/

module "prometheus_stack" {
  count = var.stack_service_replicas_env_config.PROMETHEUS_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "prometheus"
  compose_file = "docker-compose.prometheus.yml"
  replicas = {
    PROMETHEUS_REPLICAS = var.stack_service_replicas_env_config.PROMETHEUS_REPLICAS
  }

  depends_on = [terraform_data.swarm_ready]
}

module "grafana_stack" {
  count = var.stack_service_replicas_env_config.GRAFANA_REPLICAS > 0 ? 1 : 0

  source = "./modules/docker-swarm-stack"

  stack_name   = "grafana"
  compose_file = "docker-compose.grafana.yml"
  replicas = {
    GRAFANA_REPLICAS = var.stack_service_replicas_env_config.GRAFANA_REPLICAS
  }

  depends_on = [terraform_data.swarm_ready, module.prometheus_stack]
}