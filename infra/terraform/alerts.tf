# 4a) App Gateway – any unhealthy backend for 5 min
resource "azurerm_monitor_metric_alert" "agw_unhealthy" {
  name                = "agw-unhealthy-hosts"
  resource_group_name = module.resource_group.resource_group.name
  scopes              = [module.application_gateway.id]

  description   = "Any backend becomes unhealthy (UnhealthyHostCount > 0)"
  severity      = 2
  frequency     = "PT1M"
  window_size   = "PT5M"
  auto_mitigate = true

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }
}

# 4b) Container App (backend) – CPU > 70% for 5 min
resource "azurerm_monitor_metric_alert" "aca_backend_cpu" {
  name                = "aca-backend-cpu-high"
  resource_group_name = module.resource_group.resource_group.name
  scopes              = [module.container_apps["backend"].id]

  description = "Backend CPU > 70% (5m)"
  severity    = 2
  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "CpuUsage" # ACA metric
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }
}

# 4c) SQL DB – CPU > 80% for 5 min
# (module.sql_server must output the database id; see outputs.tf below)
resource "azurerm_monitor_metric_alert" "sql_cpu" {
  name                = "sqldb-cpu-high"
  resource_group_name = module.resource_group.resource_group.name
  scopes              = [module.sql_server.database_id]

  description = "SQL DB CPU > 80% (5m)"
  severity    = 2
  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}
