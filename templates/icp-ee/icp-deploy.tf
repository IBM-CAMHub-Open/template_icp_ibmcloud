
##################################
### Load the ICP image
##################################
resource "null_resource" "image_copy" {
  # Only copy image from local location if not available remotely
  count = "${var.image_location != "" && ! (substr(var.image_location, 0, 3) != "nfs"  || substr(var.image_location, 0, 4) != "http") ? 1 : 0}"

  provisioner "file" {
    connection {
      host          = "${var.boot_ipv4_address_private}"
      user          = "icpdeploy"
      private_key   = "${var.boot_private_key_pem}"
      bastion_host  = "${var.private_network_only ? var.boot_ipv4_address_private : var.boot_ipv4_address}"
    }

    source = "${var.image_location}"
    destination = "/tmp/${basename(var.image_location)}"
  }
}

module "image_load" {
    source = "git::https://github.com/IBM-CAMHub-Open/template_icp_modules.git?ref=3.2.1//public_cloud_image_load"
    # define dependency on image_copy
    image_copy_finished = "${null_resource.image_copy.id}"
    image_location = "${var.image_location}"
    boot_ipv4_address_private = "${ibm_compute_vm_instance.icp-boot.ipv4_address_private}"
    boot_ipv4_address = "${ibm_compute_vm_instance.icp-boot.ipv4_address}"
    boot_private_key_pem = "${tls_private_key.installkey.private_key_pem}"
    private_network_only = "${var.private_network_only}"
    registry_server = "${local.registry_server}"
    docker_username = "${local.docker_username}"
    docker_password = "${local.docker_password}"
}

##################################
### Deploy ICP to cluster
##################################
module "icp_provision" {
    source = "git::https://github.com/IBM-CAMHub-Open/template_icp_modules.git?ref=3.2.1//public_cloud"
    # Provide IP addresses for boot, master, mgmt, va, proxy and workers
    boot-node = "${ibm_compute_vm_instance.icp-boot.ipv4_address_private}"
    bastion_host  = "${var.private_network_only ? ibm_compute_vm_instance.icp-boot.ipv4_address_private : ibm_compute_vm_instance.icp-boot.ipv4_address}"

    #in support of workers scaling
 	  icp-worker = ["${ibm_compute_vm_instance.icp-worker.*.ipv4_address_private}"]

    icp-host-groups = {
        master = ["${ibm_compute_vm_instance.icp-master.*.ipv4_address_private}"]
        proxy = ["${ibm_compute_vm_instance.icp-proxy.*.ipv4_address_private}"]
        worker = ["${ibm_compute_vm_instance.icp-worker.*.ipv4_address_private}"]
        management = ["${ibm_compute_vm_instance.icp-mgmt.*.ipv4_address_private}"]
        va = ["${ibm_compute_vm_instance.icp-va.*.ipv4_address_private}"]
    }

    # Provide desired ICP version to provision
    icp-version = "${var.icp_inception_image}"

    /* Workaround for terraform issue #10857
     When this is fixed, we can work this out automatically */
    cluster_size  = "${1 + var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"] + var.mgmt["nodes"] + var.va["nodes"]}"

    ###################################################################################################################################
    ## You can feed in arbitrary configuration items in the icp_configuration map.
    ## Available configuration items availble from https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/installing/config_yaml.html
    icp_configuration = {
      "network_cidr"                    = "${var.network_cidr}"
      "service_cluster_ip_range"        = "${var.service_network_cidr}"
      "cluster_lb_address"              = "${ibm_lbaas.master-lbaas.vip}"
      "proxy_lb_address"                = "${ibm_lbaas.proxy-lbaas.vip}"
      "cluster_CA_domain"               = "${ibm_lbaas.master-lbaas.vip}"
      "cluster_name"                    = "${var.deployment}"
      "calico_ip_autodetection_method"  = "interface=eth0"

      # An admin password will be generated if not supplied in terraform.tfvars
      "default_admin_password"          = "${local.icppassword}"

      # This is the list of disabled management services
      "management_services"             = "${local.disabled_management_services}"

      "private_registry_enabled"        = "true"
      "image_repo"                      = "${local.image_repo}" # Will either be our private repo or external repo
      "docker_username"                 = "${local.docker_username}" # Will either be username generated by us or supplied by user
      "docker_password"                 = "${local.docker_password}" # Will either be username generated by us or supplied by user
    }

    # We will let terraform generate a new ssh keypair
    # for boot master to communicate with worker and proxy nodes
    # during ICP deployment
    generate_key = true

    # SSH user and key for terraform to connect to newly created VMs
    # ssh_key is the private key corresponding to the public assumed to be included in the template
    ssh_user        = "icpdeploy"
    ssh_key_base64  = "${base64encode(tls_private_key.installkey.private_key_pem)}"
    ssh_agent       = false
    image_load_finished       = "${module.image_load.image_load_finished}"
    #image_location  = "${var.image_location}"
    # Make sure to wait for image load to complete
    #hooks = {
    #  "boot-preconfig" = [
    #    "while [ ! -f /opt/ibm/.imageload_complete ]; do sleep 5; done"
    #  ]
    #}

    ## Alternative approach
    # hooks = {
    #   "cluster-preconfig" = ["echo No hook"]
    #   "cluster-postconfig" = ["echo No hook"]
    #   "preinstall" = ["echo No hook"]
    #   "postinstall" = ["echo No hook"]
    #   "boot-preconfig" = [
    #     # "${var.image_location == "" ? "exit 0" : "echo Getting archives"}",
    #     "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
    #     "sudo mv /tmp/load_image.sh /opt/ibm/scripts/",
    #     "sudo chmod a+x /opt/ibm/scripts/load_image.sh",
    #     "/opt/ibm/scripts/load_image.sh -p ${var.image_location} -r ${local.registry_server} -c ${local.docker_password}"
    #   ]
    # }

}