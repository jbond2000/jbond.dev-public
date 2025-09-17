resource "azurerm_resource_group" "jbondcloudrg" {
  name     = var.jbondcloudrg_name
  location = var.rg_location
}

resource "azurerm_storage_account" "stjbondcloud" {
  name                     = var.jbcloud_sa_name
  resource_group_name      = azurerm_resource_group.jbondcloudrg.name
  location                 = var.sa_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "site" {
  storage_account_id = azurerm_storage_account.stjbondcloud.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

resource "azurerm_dns_zone" "jbond_dev" {
  name                = var.dns_zone_jbond_dev
  resource_group_name = azurerm_resource_group.jbondcloudrg.name
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_account_name
  location            = var.rg_location
  resource_group_name = var.jbondcloudrg_name
  kind                = "GlobalDocumentDB"
  offer_type          = "Standard"

  capabilities { name = "EnableServerless" }

  consistency_policy { consistency_level = "Session" }

  geo_location {
    location          = var.rg_location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "users" {
  name                = var.cosmos_db_name
  resource_group_name = var.jbondcloudrg_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "tutorial-container" {
  name                = var.cosmos_container_name
  resource_group_name = var.jbondcloudrg_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.users.name
  partition_key_paths = ["/date"]
  
}

resource "azurerm_service_plan" "asp" {
  name                = "ASP-jbondcloudrg-8c16"
  resource_group_name = var.jbondcloudrg_name
  location            = var.rg_location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_windows_function_app" "res-0" {
  name                = "jbonddevcounter"
  resource_group_name = var.jbondcloudrg_name
  location            = var.rg_location
  https_only          = true
  public_network_access_enabled = true
  service_plan_id     = "/subscriptions/a67fa08c-8a71-4843-a6e9-1fbd1d8198b6/resourceGroups/jbondcloudrg/providers/Microsoft.Web/serverFarms/ASP-jbondcloudrg-8c16"

  storage_account_name       = azurerm_storage_account.stjbondcloud.name
  storage_account_access_key = azurerm_storage_account.stjbondcloud.primary_access_key

  # Functions v4 + Node worker
  functions_extension_version = "~4"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME      = "node"
    WEBSITE_NODE_DEFAULT_VERSION  = "~20"
  }

  site_config {
    minimum_tls_version = "1.2"
    http2_enabled       = true
    application_stack {
      node_version = "~20"   # <-- switch from dotnet to node
    }
  }
}


resource "azurerm_static_web_app" "swa" {
  name                = var.swa_name
  resource_group_name = azurerm_resource_group.jbondcloudrg.name
  location            = var.swa_location
  sku_tier            = "Free"
}

resource "azurerm_dns_cname_record" "www" {
  name                = var.www_label
  zone_name           = azurerm_dns_zone.jbond_dev.name
  resource_group_name = azurerm_resource_group.jbondcloudrg.name
  ttl                 = 300
  record              = azurerm_static_web_app.swa.default_host_name
}

resource "azurerm_static_web_app_custom_domain" "www" {
  static_web_app_id = azurerm_static_web_app.swa.id
  domain_name       = "${var.www_label}.${var.root_domain}"
  validation_type   = "cname-delegation"
  depends_on        = [azurerm_dns_cname_record.www]
}
