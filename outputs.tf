locals {
  ip_address = aws_eip.pub_addr_1.public_ip
}

output "informations" {
  value = {
    http   = "http://${local.ip_address}/"
    https  = "https://${local.ip_address}/"
    ip     = local.ip_address,
    prefix = var.prefix
    ssh    = "ssh -i ./ssh/key admin@${local.ip_address}"
  }
}
