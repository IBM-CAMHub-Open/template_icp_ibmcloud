output "ibm_cloud_private_boot_ip" {
  value = "https://${element(ibm_compute_vm_instance.icp-boot.*.ipv4_address, 0)}"
}

output "ibm_cloud_private_master_ip" {
  value = "https://${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}"
}

output "ICP Console URL" {
  value = "https://${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}:8443"
}

output "ICP Proxy" {
  value = "${element(ibm_compute_vm_instance.icp-proxy.*.ipv4_address, 0)}"
}

output "ICP Kubernetes API URL" {
  value = "https://${element(ibm_compute_vm_instance.icp-master.*.ipv4_address, 0)}:8001"
}

output "ICP Admin Username" {
  value = "admin"
}

output "ICP Admin Password" {
  value = "${local.icppassword}"
}