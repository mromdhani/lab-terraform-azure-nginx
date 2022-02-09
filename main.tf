provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_lab" {
  name     = "my-resource-group-lab-06"
  location = "West Europe"
}

module "linuxservers" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg_lab.name
  vm_os_simple        = "UbuntuServer"
  public_ip_dns       = ["my-nginx-server"] // change to a unique name per datacenter region
  vnet_subnet_id      = module.network.vnet_subnets[0]  
  
  # Want to be sure that we have Ubuntu 20.04 ?

  depends_on = [azurerm_resource_group.rg_lab]

  vm_hostname                      = "mylinuxvm"
  nb_public_ip                     = 1
  remote_port                      = "22"
  nb_instances                     = 1
  vm_os_publisher                  = "Canonical"
  vm_os_offer                      = "UbuntuServer"
  vm_os_sku                        = "18.04-LTS"

  boot_diagnostics                 = true
  delete_os_disk_on_termination    = true
  nb_data_disk                     = 1
  data_disk_size_gb                = 20
  data_sa_type                     = "Standard_LRS"    # "Premium_LRS"
  enable_ssh_key                   = true
  ssh_key_values                   = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFGXTjNzm9Ba1EZch4P67hGvN7hYUzid7323A8Lh796/TYFXeqQ/aWO9mNmWZKMjsrFwTfF80GpccNsBMoCUVaE3x4tvER94zccU51HNlTdSG1jxjy2jbXm91sxvG3blxpAYWiafJ7y6Sb/rQF5Zq7vs24nIzchn+zO2GCvMBm4Y6tvUC6Kkmq/8BysjEoHmRlTrhSpzmDRR6hgFQ2BUHGi120dBDbribk4m7TyaUfNqxV7LI90VbPAVTuBnvKmmJzGbK66kRP0kIMCY6fbI50sVAabDu/Ki5z9r0wiSlb38y9sXgQyMImr4r8rcrmI3iaS7dcGlhmTV/WIBRc44kJwB+I9OiFkn2/pviI/Z0pxSGjVk6P0FvwpX8IStOem0BM8F1KND0mabfIdShN1AW0vU1OQ3kchbgTOZRUvZqzCD6on46q2un+AodhdS8gle3kJaRuqpfn7T2OHgrqNPvkLPQEejawUEn/ZF8DbD3Jdiw/DpY8MJo9PTWKgsPE3Fc= student@ROME3-0"]
  vm_size                          = "Standard_DS1_v2"
  delete_data_disks_on_termination = true

   connection {
    type         = "ssh"
    user         = "azureuser"
    private_key  = file("~/.ssh/id_rsa")
    host         = self.public_ip_addres
                # module.linuxservers.public_ip_address
   }
  provisioner "file" {
      source      = "./scripts/setup-nginx.sh"
      destination = "/var/tmp"  
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /var/tmp/setup-nginx.sh",
      "/var/tmp/setup-nginx.sh",
       "echo '===== Provionner is on its way ====='"
    ]
  }

}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.rg_lab.name
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  depends_on = [azurerm_resource_group.rg_lab]
}
