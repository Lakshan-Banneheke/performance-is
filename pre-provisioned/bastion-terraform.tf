# -------------------------------------------------------------------------------------
#
# Copyright (c) 2021, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
#
# This software is the property of WSO2 Inc. and its suppliers, if any.
# Dissemination of any information or reproduction of any material contained
# herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
# You may not alter or remove any copyright or other notice from copies of this content.
#
# --------------------------------------------------------------------------------------

locals {
  json_data = jsondecode(file("parameters.json"))
  default_tags = {
    project     = "thunder"
    environment = "rnd"
    terraform   = "true"
    usecase     = "thunder-performance-testing-vm"
  }
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.99.0"
    }
  }
}

provider "azurerm" {
  use_msi = true
  subscription_id = "{SUBSCRIPTION_ID}"
  client_id       = "{CLIENT_ID}"
  client_secret   = "{CLIENT_SECRET}"
  tenant_id       = "{TENANT_ID}"
  features {}
}

# Create public IPs
resource "azurerm_public_ip" "performance_testing_public_ip" {
  name                         = local.json_data.publicIpAddressName.value
  location                     = local.json_data.location.value
  resource_group_name          = local.json_data.resourceGroupName.value
  allocation_method            = "Static"
  sku = local.json_data.publicIpAddressSku.value
  availability_zone = local.json_data.zone.value

  tags = local.default_tags
}

# Create network interface
resource "azurerm_network_interface" "performance_testing_nic" {
  name                      = local.json_data.networkInterfaceName.value
  location                  = local.json_data.location.value
  resource_group_name       = local.json_data.resourceGroupName.value
  depends_on                = [azurerm_public_ip.performance_testing_public_ip]

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/MC_rg-thunder_aks-thunder-eastus2-001_eastus2/providers/Microsoft.Network/virtualNetworks/aks-vnet-35856653/subnets/snet-perf-vm"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.performance_testing_public_ip.id
  }

  tags = local.default_tags
}

resource "azurerm_linux_virtual_machine" "performance_testing_linux_vm" {
  name                = local.json_data.virtualMachineName.value
  resource_group_name = local.json_data.resourceGroupName.value
  location            = local.json_data.location.value
  size                = local.json_data.virtualMachineSize.value
  depends_on = [azurerm_network_interface.performance_testing_nic]
  network_interface_ids = [azurerm_network_interface.performance_testing_nic.id]
  computer_name = local.json_data.virtualMachineComputerName.value
  admin_username      = local.json_data.adminUsername.value

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = local.json_data.adminUsername.value
    public_key = file("public.pub")
  }

  os_disk {
    name = "myosdisk"
    caching              = "ReadWrite"
    storage_account_type = local.json_data.osDiskType.value
    disk_size_gb         = "50"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  zone = local.json_data.zone.value

  tags = local.default_tags
}

resource "azurerm_virtual_machine_extension" "aad_ssh_login" {
  name                 = "AADSSHLoginForLinux "
  virtual_machine_id   = azurerm_linux_virtual_machine.performance_testing_linux_vm.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
}

resource "azurerm_virtual_machine_extension" "performance_testing_linux_script" {
  name                 = "setup-performance_testing_linux_virtual_machine"
  virtual_machine_id   = azurerm_linux_virtual_machine.performance_testing_linux_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "script": "${base64encode(templatefile("setup_script.sh", {
          user="{bastion_user}"
        }))}"
    }
SETTINGS
}

output "public_ip_address" {
  value = azurerm_public_ip.performance_testing_public_ip.ip_address
}

output "private_ip_address" {
  value = azurerm_network_interface.performance_testing_nic.private_ip_address
}
