output "ibm_cloud_private_boot_ip" {
  value = "${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}"
}

output "ibm_cloud_private_master_ip" {
  value = "${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}"
}

output "ibm_cloud_private_console_url" {
  value = "https://${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}:8443"
}

output "ibm_cloud_private_kubernetes_api_url" {
  value = "https://${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}:8001"
}

output "ibm_cloud_private_ca_domain_name" {
  value = "${var.deployment}.icp"
}

output "ICP Proxy" {
  value = "${element(ibm_compute_vm_instance.icp-proxy.*.ipv4_address, 0)}"
}

output "ICP Admin Username" {
  value = "admin"
}

output "ibm_cloud_private_admin_password" {
  value = "${local.icppassword}"
}