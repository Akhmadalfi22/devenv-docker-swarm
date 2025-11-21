locals {
  stack_name = var.stack_name

  stack_replicas_env = join(" ", [
    for service_replicas_env, replica_count in var.replicas :
    "${service_replicas_env}=${replica_count}"
  ])

  compose_hash  = filesha256(var.compose_file)
  config_files  = fileset("${path.cwd}/config/${var.stack_name}", "*")                                    # Get all stack config files
  config_hashes = [for f in local.config_files : filesha256("${path.cwd}/config/${var.stack_name}/${f}")] # Read each stack config file and hashes it
  config_hash   = sha256(join("", local.config_hashes))
}

# Create Docker Stack Secrets
resource "terraform_data" "docker_secrets" {
  for_each = nonsensitive(var.secrets)

  input = {
    secret_name  = each.value.name
    secret_value = var.secrets[each.key].value
  }

  provisioner "local-exec" {
    command     = "echo '${self.input.secret_value}' | docker secret create ${self.input.secret_name} -"
    working_dir = path.cwd
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "docker secret rm ${self.input.secret_name}"
    working_dir = path.cwd
  }
}

# Deploy Docker Stack
resource "terraform_data" "deploy_stack" {
  input = {
    stack_name   = local.stack_name
    compose_file = var.compose_file
    replicas     = var.replicas
    wait_for     = var.wait_for
  }

  provisioner "local-exec" {
    command     = <<EOT
      bash -c '
      for wait_for_stack in ${join(" ", self.input.wait_for)}; do
        echo "Waiting for stack $wait_for_stack..."

        while true; do
          all_running=true

          while IFS="|" read -r name state error; do
            if [[ "$state" != Running* ]]; then
              all_running=false
              echo "Stack $name is not running: $state"
              [[ -n "$error" ]] && echo "Stack error: $error"
            else
              echo "Stack $name is running."
            fi
          done < <(docker stack ps "$wait_for_stack" --no-trunc --format "{{.Name}}|{{.DesiredState}}|{{.Error}}" 2>/dev/null)

          if $all_running; then
            echo "All services in stack $wait_for_stack are running."
            break
          fi

          echo "Waiting for stack $wait_for_stack..."
          sleep 5
        done
      done

      ${local.stack_replicas_env} docker stack deploy --resolve-image changed -c ${self.input.compose_file} ${self.input.stack_name}
      '
      EOT
    working_dir = path.cwd
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
      docker stack rm ${self.input.stack_name} || true
      while docker stack ps ${self.input.stack_name} --no-trunc --format '{{.Name}}' 2>/dev/null | grep -q .; do
        echo "Waiting for stack ${self.input.stack_name} to be removed..."
        sleep 2
      done
      echo "Stack ${self.input.stack_name} removed."
    EOT
    working_dir = path.cwd
  }

  depends_on = [terraform_data.docker_secrets]
}

# Handle replica changes
resource "terraform_data" "stack_replicas_update" {
  triggers_replace = {
    replicas     = jsonencode(var.replicas)
    compose_hash = local.compose_hash # Deterministic fingerprint for stack compose file
    config_hash  = local.config_hash  # # Deterministic fingerprint for combined stack configuration files
  }

  depends_on = [terraform_data.deploy_stack]

  provisioner "local-exec" {
    command     = "${local.stack_replicas_env} docker stack deploy --resolve-image changed -c ${var.compose_file} ${var.stack_name}"
    working_dir = path.cwd
  }
}

