variable "subscription_id" {
  description = "Azure subscription ID. Use your own subscription ID; do not commit secrets."
  type        = string

  validation {
    condition     = trimspace(var.subscription_id) != ""
    error_message = "subscription_id must not be empty."
  }
}

variable "project_name" {
  description = "Prefix used for Azure resource names."
  type        = string
  default     = "azure-jenkins-cicd"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "Central India"
}

variable "vm_size" {
  description = "Azure VM size; availability and pricing depend on your subscription and region."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Linux VM administrator username."
  type        = string
  default     = "azureuser"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{2,31}$", var.admin_username))
    error_message = "admin_username must be 3-32 characters and contain only lowercase letters, numbers, underscores, or hyphens."
  }
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key file."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "admin_ip_cidr" {
  description = "Your public IPv4 CIDR allowed to SSH, for example 203.0.113.10/32. Replace the example."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_ip_cidr, 0)) && var.admin_ip_cidr != "0.0.0.0/0"
    error_message = "admin_ip_cidr must be a valid CIDR and must not allow SSH from 0.0.0.0/0."
  }
}
