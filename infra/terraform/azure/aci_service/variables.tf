variable "name" { type = string }
variable "rg_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }

variable "image" { type = string }
variable "ports" { type = list(number) } # e.g. [80] or [8080]
variable "env" {
  type    = map(string)
  default = {}
}

# CPU/Memory defaults
variable "cpu" {
  type    = number
  default = 1
}
variable "memory" {
  type    = number
  default = 1.5
}
variable "registry_server" {
  type    = string
  default = "index.docker.io"
} # try "https://index.docker.io/v1/" if needed
variable "registry_username" {
  type    = string
  default = ""
} # your Docker Hub username
variable "registry_password" {
  type      = string
  default   = ""
  sensitive = true
} # a Docker Hub access token (not your password)
