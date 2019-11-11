output "ibm_cloud_private_boot_ip" {
  value = "${element(ibm_compute_vm_instance.icp-boot.*.ipv4_address, 0)}"
}

output "ibm_cloud_private_master_ip" {
  value = "${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}"
}

output "ibm_cloud_private_console_url" {
  value = "https://${ibm_lbaas.master-lbaas.vip}:8443"
}

output "ibm_cloud_private_kubernetes_api_url" {
  value = "https://${ibm_lbaas.master-lbaas.vip}:8001"
}

output "ibm_cloud_private_registry_server" {
  value = "${local.registry_server}"
}

output "ibm_cloud_private_ca_domain_name" {
  value = "${ibm_lbaas.master-lbaas.vip}"
}

output "ibm_cloud_private_admin_password" {
  value = "${local.icppassword}"
}

output "ICP Console load balancer DNS (external)" {
  value = "${ibm_lbaas.master-lbaas.vip}"
}

output "ICP Proxy load balancer DNS (external)" {
  value = "${ibm_lbaas.proxy-lbaas.vip}"
}

output "ICP Admin Username" {
  value = "admin"
}
output "connection_name" {
	value = "${var.deployment}${random_id.clusterid.hex}"
}

output "registry_ca_cert"{
  value = "${module.gather_output.registry_ca_cert}"
} 

output "icp_install_dir"{
  value = "${module.gather_output.icp_install_dir}"
} 

output "registry_config_do_name"{
	value = "${var.deployment}${random_id.clusterid.hex}RegistryConfig"
}