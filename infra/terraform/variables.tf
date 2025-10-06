
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string

}
variable "rg_name" { type = string }
variable "rg_location" { type = string }
variable "fe_image" { type = string }
variable "be_image" { type = string }




variable "dockerhub_username" {
  type    = string
  default = ""
}

variable "dockerhub_token" {
  type      = string
  default   = ""
  sensitive = true
}

