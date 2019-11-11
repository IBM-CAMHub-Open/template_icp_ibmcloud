# ICP Community Edition (CE) with load balancers on IBM Cloud

This Terraform example configurations uses the [IBM Cloud  provider](https://ibm-cloud.github.io/tf-ibm-docs/index.html) to provision virtual machines on IBM Cloud Infrastructure (SoftLayer)
and [Terraform Module ICP Deploy](https://github.com/IBM-CAMHub-Open/template_icp_modules/tree/master/public_cloud) to prepare VSIs and deploy [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) version 3.2.1.  This Terraform template automates best practices learned from installing ICP on IBM Cloud Infrastructure.

## Deployment overview
This template creates an environment where
 - Cluster is deployed on private network and is accessed through load balancers
 - Most ICP services disabled 
 - Minimal VM sizes
 - No separate boot node
 
The default configuration deploys a 6 node and 2 load balancers topology as follows: 
 - One master node 
 - One proxy node
 - One management node
 - Three worker nodes
 - One master load balancer
 - One proxy load balancer


## Architecture Diagram

![Architecture](../../static/icp_ce_minimal_with_lb.png)

## Pre-requisites

* The template is tested on VSIs based on Ubuntu 16.04.  RHEL is not supported in this automation.



### Automation Notes

#### What does the automation do
1. Create the virtual machines as defined in `camvariables.json`
   - Use cloud-init to add a user `icpdeploy` with a randomly generated ssh-key
   - Configure a separate hard disk to be used by docker
2. Create security groups and rules for cluster communication as declared in [security_group.tf](security_group.tf)
3. Handover to the [icp-deploy](https://github.com/IBM-CAMHub-Open/template_icp_modules/tree/master/public_cloud) terraform module 

#### What does the icp deploy module do
1. It uses the provided ssh key which has been generated for the `icpdeploy` user to ssh from the terraform controller to all cluster nodes to install ICP prerequisites
2. It generates a new ssh keypair for ICP Boot(master) node to ICP cluster communication and distributes the public key to the cluster nodes. This key is used by the ICP Ansible installer.
3. It populates the necessary `/etc/hosts` file on the boot node
4. It generates the ICP cluster hosts file based on information provided in [icp-deploy.tf](icp-deploy.tf)
5. It generates the ICP cluster `config.yaml` file based on information provided in [icp-deploy.tf](icp-deploy.tf)

#### Security Groups

The automation leverages Security Groups to lock down public and private access to the cluster.

- Inbound communication to the master and proxy nodes are only permitted on ports from the private subnet that the LBaaS is provisioned on.
- Inbound SSH to the cluster nodes is permitted from all addresses on the internet to ease exploration and investigation.
- All outbound communication is allowed.
- All other communication is only permitted between cluster nodes.

#### LBaaS

The automation exposes the Master control plane to the Internet on:
- TCP port 8443 (master console)
- TCP port 8500 (private registry)
- TCP port 8600 (private registry)
- TCP port 8001 (Kubernetes API)
- TCP port 9443 (OIDC authentication endpoint)

The automation exposes the Proxy nodes to the internet on:
- TCP port 443 (https)
- TCP port 80 (http)

### Terraform configuration

Please see [variables.tf](variables.tf) for additional parameters.

| name | required                        | value        |
|----------------|------------|--------------|
| `key_name`   | no           | Array of SSH keys to add to `root` for all created VSI instances.  Note that the automation generates its own SSH keys so these are additional keys that can be used for access |
| `datacenter`   | yes           | Datacenter to place all objects in |
| `os_reference_code`   | yes           | OS to install on the VSIs.  Use the [API](https://api.softlayer.com/rest/v3/SoftLayer_Virtual_Guest_Block_Device_Template_Group/getVhdImportSoftwareDescriptions.json?objectMask=referenceCode) to determine valid values. Only Ubuntu 16.04 was tested. Note that the boot node OS can be specified separately (defaults to `UBUNTU_16_64` to save licensing costs). |
| `icp_inception_image` | yes | The ICP installer image to use.  This corresponds to the version of ICP to install. Defaults to 3.1.0 |
| `docker_package_location` | no | The local path to where the IBM-provided docker installation binary is saved. If not specified and using Ubuntu, will install latest `docker-ce` off public repo. |
| `private_network_only` | no | Specify true to remove the cluster from the public network. If public network access is disabled, note that to allow outbound internet access you will require a Gateway Appliance on the VLAN to do Source NAT. Additionally, the automation requires SSH access to the boot node to provision ICP, so a VPN tunnel may be required.  The LBaaS for both the master and the control plane will still be provisioned on the public internet, but the cluster nodes will not have public addresses configured. |
| `private_vlan_router_hostname` | no | Private VLAN router to place all VSIs behind.  e.g. bcr01a. See Network > IP Management > VLANs in the portal. Leave blank to let the system choose. This option should be used when setting `private_network_only` to true along with `private_vlan_number` using a private VLAN that is routed with a Gateway Appliance. |
| `private_vlan_number` | no | Private VLAN number to place all VSIs on.  e.g. 1211. See Network > IP Management > VLANs in the portal. Leave blank to let the system choose. This option should be used when setting `private_network_only` to true along with `private_vlan_router_hostname`, using a private VLAN that is routed with a Gateway Appliance.|
| `public_vlan_router_hostname` | no | Public VLAN router to place all VSIs behind.  e.g. fcr01a. See Network > IP Management > VLANs in the portal. Leave blank to let the system choose. |
| `public_vlan_number` | no | Public VLAN number to place all VSIs on.  e.g. 1211. See Network > IP Management > VLANs in the portal. Leave blank to let the system choose. |
| `icppassword` | no | ICP administrator password.  One will be generated if not set. |
| `deployment` | no | Identifier prefix added to the host names of all your infrastructure resources for organising/naming ease |

