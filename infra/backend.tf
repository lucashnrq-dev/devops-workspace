terraform {
    backend "azurerm" {
        resource_group_name = "rg-tfstate"
        storage_account_name = "tfstatecurso4124"
        container_name = "tfstate"
        key = "terraform.tfstate"
    }
}
