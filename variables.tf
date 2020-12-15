variable "prefix" {
  description = <<-EOT
    Prefix for all resources created by this configuration. Use an
    abbreviation of your name. For example, 'jdoe' for John Doe.
  EOT

  type        = string
  default     = "user"
}

variable "aws_region" {
  description = "AWS region to launch servers in."

  type        = string
  default     = "eu-central-1" # Frankfurt (Germany)
}

# region suffix (appended behind aws_region)
variable "aws_zone" {
  description = "AWS zone to launch servers in."

  type        = string
  default     = "a"
}

variable "accessible_from" {
  description = <<-EOT
    A list of networks from which the entire deployment will be accessible,
    specified in CIDR format.
  EOT

  type        = list(string)
  default     = null
}

variable "ssh_public_key_path" {
  description = <<-EOT
    Path to the SSH public key to be used for authentication. Ensure this
    keypair is added to your local SSH agent so provisioners can connect.
  EOT

  type        = string
  default     = "./ssh/key.pub"
}
