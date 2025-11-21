variable "stack_name" {
  description = "Name of the Docker stack"
  type        = string
}

variable "compose_file" {
  description = "Docker Compose file name"
  type        = string
}

variable "replicas" {
  description = "Stack services replicas"
  type        = map(number)
  default     = {}
}

variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    name  = string
    value = string
  }))
  default   = {}
  sensitive = true
}

variable "wait_for" {
  description = "Wait for stacks"
  type        = list(string)
  default     = []
}