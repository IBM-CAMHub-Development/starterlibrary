provider "ibm" {
  region = var.region
}

module "camtags" {
  source = "../Modules/camtags"
}

data "ibm_is_image" "ds_image" {
  name = var.image_name
}

#Create VPC
resource "ibm_is_vpc" "cam_vpc" {
  name = "cam-vpc"
  tags = module.camtags.tagslist
}

#Create Subnet
resource "ibm_is_subnet" "cam_subnet" {
  name            = "cam-subnet"
  vpc             = ibm_is_vpc.cam_vpc.id
  zone            = var.zone
  ipv4_cidr_block = "10.241.0.0/24"
}

#Create SSHKey
resource "ibm_is_ssh_key" "cam_sshkey" {
  name       = "cam-ssh"
  public_key = var.public_ssh_key
}

#Create VSI
resource "ibm_is_instance" "cam-server" {
  name    = "cam-server-vsi"
  image   = data.ibm_is_image.ds_image.id
  profile = var.profile

  primary_network_interface {
    subnet = ibm_is_subnet.cam_subnet.id
  }

  vpc  = ibm_is_vpc.cam_vpc.id
  zone = var.zone
  keys = [ibm_is_ssh_key.cam_sshkey.id]
  tags = module.camtags.tagslist
}

## Attach floating IP address to VSI
resource "ibm_is_floating_ip" "cam_floatingip" {
  name   = "cam-fip"
  target = ibm_is_instance.cam-server.primary_network_interface[0].id
}
