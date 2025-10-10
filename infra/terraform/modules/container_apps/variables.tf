variable "name" {
  description = "Name of the Container App"
  type        = string
}

variable "container_app_environment_id" {
  description = "ID of the Container App Environment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "revision_mode" {
  description = "Revision mode for the container app"
  type        = string
  default     = "Single"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "image" {
  description = "Container image"
  type        = string
}

variable "cpu" {
  description = "CPU allocation"
  type        = number
}

variable "memory" {
  description = "Memory allocation"
  type        = string
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "ingress_enabled" {
  description = "Whether to enable ingress"
  type        = bool
}

variable "allow_insecure_connections" {
  description = "Allow insecure HTTP connections"
  type        = bool
}

variable "external_enabled" {
  description = "Enable external ingress"
  type        = bool
}

variable "target_port" {
  description = "Target port for ingress"
  type        = number
}

variable "ip_security_restrictions" {
  type = list(object({
    name             = string
    description      = optional(string)
    action           = string # "Allow" or "Deny"
    ip_address_range = string # e.g., "104.45.51.226/32"
  }))
  default = []
}


variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
variable "log_analytics_workspace_id" {
  description = "LAW id for diagnostics"
  type        = string
}
