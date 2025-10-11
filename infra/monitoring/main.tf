terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    time    = { source = "hashicorp/time", version = "~> 0.10" }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# --------------------------
# Lookups (no creation here)
# --------------------------
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

data "azurerm_application_gateway" "agw" {
  name                = var.appgw_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_container_app" "frontend" {
  name                = var.frontend_ca_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_container_app" "backend" {
  name                = var.backend_ca_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_mssql_server" "sql" {
  name                = var.sql_server_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_mssql_database" "db" {
  name      = var.sql_database_name
  server_id = data.azurerm_mssql_server.sql.id
}

# ------------------------------------------------
# (Optional) Workspace-based Application Insights
# ------------------------------------------------
resource "azurerm_application_insights" "frontend" {
  name                = "${var.frontend_ca_name}-appi"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.rg_name
  workspace_id        = data.azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

resource "azurerm_application_insights" "backend" {
  name                = "${var.backend_ca_name}-appi"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.rg_name
  workspace_id        = data.azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

# -----------------------------------
# Diagnostic settings (AGW -> LAW)
# -----------------------------------
resource "azurerm_monitor_diagnostic_setting" "agw_to_law" {
  name                       = "agw-to-law"
  target_resource_id         = data.azurerm_application_gateway.agw.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id

  enabled_log    { category = "ApplicationGatewayAccessLog" }
  enabled_log    { category = "ApplicationGatewayPerformanceLog" }
  enabled_log    { category = "ApplicationGatewayFirewallLog" }
  enabled_metric { category = "AllMetrics" }
}

# small delay to avoid race on fresh infra
resource "time_sleep" "after_infra" {
  create_duration = "45s"
}

# -----------------------------------
# Action group (optional email)
# -----------------------------------
resource "azurerm_monitor_action_group" "ops" {
  name                = "ops-ag"
  short_name          = "ops"
  resource_group_name = data.azurerm_resource_group.rg.name

  dynamic "email_receiver" {
    for_each = var.alert_email == null ? [] : [1]
    content {
      name          = "primary"
      email_address = var.alert_email
    }
  }
}

# --------------------------
# Alerts
# --------------------------

# 1) App Gateway: any unhealthy backend for 5m
resource "azurerm_monitor_metric_alert" "agw_unhealthy" {
  name                = "agw-unhealthy-hosts"
  resource_group_name = data.azurerm_resource_group.rg.name
  scopes              = [data.azurerm_application_gateway.agw.id]
  description         = "Any backend becomes unhealthy"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  depends_on          = [azurerm_monitor_diagnostic_setting.agw_to_law, time_sleep.after_infra]

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  dynamic "action" {
    for_each = var.alert_email == null ? [] : [1]
    content { action_group_id = azurerm_monitor_action_group.ops.id }
  }
}

# 2) App Gateway: failed requests > 0 for 5m (replaces ACA Http5xx/RequestsFailed)
resource "azurerm_monitor_metric_alert" "agw_failed_requests" {
  name                = "agw-failed-requests"
  resource_group_name = data.azurerm_resource_group.rg.name
  scopes              = [data.azurerm_application_gateway.agw.id]
  description         = "App Gateway seeing failed requests (non-2xx/3xx)"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  depends_on          = [azurerm_monitor_diagnostic_setting.agw_to_law, time_sleep.after_infra]

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "FailedRequests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  dynamic "action" {
    for_each = var.alert_email == null ? [] : [1]
    content { action_group_id = azurerm_monitor_action_group.ops.id }
  }
}

# 3) SQL DB: CPU > 80% for 5m
resource "azurerm_monitor_metric_alert" "sql_cpu" {
  name                = "sqldb-cpu-high"
  resource_group_name = data.azurerm_resource_group.rg.name
  scopes              = [data.azurerm_mssql_database.db.id]
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  depends_on          = [time_sleep.after_infra]

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  dynamic "action" {
    for_each = var.alert_email == null ? [] : [1]
    content { action_group_id = azurerm_monitor_action_group.ops.id }
  }
}
