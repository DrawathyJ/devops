output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_public_ip" {
  description = "Public IP address of the web server VM."
  value       = azurerm_public_ip.public_ip.ip_address
}

output "website_url" {
  description = "Website URL. HTTP is used for this learning demo."
  value       = "http://${azurerm_public_ip.public_ip.ip_address}"
}
